# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

import boto3
import botocore
from botocore.config import Config
from botocore.exceptions import ClientError
import json
import time
import os
import logging
import subprocess
import traceback
import random
import signal
import sys
import base64
import asyncio
import requests
import psutil

from functools import partial
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch
from aws_xray_sdk import global_sdk_config

from api.in_out_manager import in_out_manager
from api.queue_manager import queue_manager

from utils.performance_tracker import EventsCounter, performance_tracker_initializer
from utils.state_table_common import *
from utils.ttl_experation_generator import TTLExpirationGenerator
import utils.grid_error_logger as errlog

import logging
logging.basicConfig(format="%(asctime)s - %(levelname)s - %(filename)s - %(funcName)s  - %(lineno)d - %(message)s",datefmt='%H:%M:%S', level=logging.INFO)


# Uncomment to get tracing on interruption
# import faulthandler
# faulthandler.enable(file=sys.stderr, all_threads=True)


logging.basicConfig(
    format="{ \"filename\" : \"%(filename).7s.py\", "
           "\"functionName\" : \"%(funcName).5s\", "
           "\"line\" : \"%(lineno)4d\" , "
           "\"time\" : \"%(asctime)s\","
           "\"level\":\"%(levelname)5s\","
           "\"message\" : \"%(message)s\" }",
    datefmt='%H:%M:%S', level=logging.INFO)

logging.getLogger('aws_xray_sdk').setLevel(logging.DEBUG)

# Uncomment to get DEBUG logging
# boto3.set_stream_logger('', logging.DEBUG)

rand_delay = random.randint(5, 15)
logging.info("SLEEP DELAY 2 {}".format(rand_delay))
time.sleep(rand_delay)

session = boto3.session.Session()

try:
    agent_config_file = os.environ['AGENT_CONFIG_FILE']
except KeyError:
    agent_config_file = "/etc/agent/Agent_config.tfvars.json"

with open(agent_config_file, 'r') as file:
    agent_config_data = json.loads(file.read())

# If there are no tasks in the queue we do not attempt to retrieve new tasks for that interval

empty_task_queue_backoff_timeout_sec = agent_config_data['empty_task_queue_backoff_timeout_sec']
work_proc_status_pull_interval_sec = agent_config_data['work_proc_status_pull_interval_sec']
task_ttl_expiration_offset_sec = agent_config_data['task_ttl_expiration_offset_sec']
task_ttl_refresh_interval_sec = agent_config_data['task_ttl_refresh_interval_sec']
task_input_passed_via_external_storage = agent_config_data['task_input_passed_via_external_storage']
agent_sqs_visibility_timeout_sec = agent_config_data['agent_sqs_visibility_timeout_sec']
USE_CC = agent_config_data['agent_use_congestion_control']
IS_XRAY_ENABLE = agent_config_data['enable_xray']
region = agent_config_data["region"]
# TODO: redirect logs to fluentD

AGENT_EXEC_TIMESTAMP_MS = 0
execution_is_completed_flag = 0

try:
    SELF_ID = os.environ['MY_POD_NAME']
except KeyError:
    SELF_ID = "1234"
    pass

# TODO - retreive the endpoint url from Terraform
# sqs = boto3.resource('sqs', endpoint_url=agent_config_data['sqs_endpoint'], region_name=region)
# sqs = boto3.resource('sqs', region_name=region)
# tasks_queue = sqs.get_queue_by_name(QueueName=agent_config_data['sqs_queue'])
logging.info("Create sqs queue")
from api.state_table_manager import state_table_manager



tasks_queue = queue_manager(
    grid_queue_service=agent_config_data['grid_queue_service'],
    grid_queue_config=agent_config_data['grid_queue_config'],
    endpoint_url=agent_config_data["sqs_endpoint_url"],
    queue_name=agent_config_data['tasks_queue_name'],
    region=region)


lambda_cfg = botocore.config.Config(retries={'max_attempts': 3}, read_timeout=2000, connect_timeout=2000,
                                    region_name=region)
lambda_client = boto3.client('lambda', config=lambda_cfg, endpoint_url=os.environ['LAMBDA_ENDPOINT_URL'],
                             region_name=region)


# TODO: We are using two retry logics for accessing DynamoDB config, and config_cc (for congestion control)
# Revisit this code and unify the logic.
config = {
    "retries": {
        'max_attempts': 5,
        'mode': 'standard'
    }
}
# dynamodb = boto3.resource('dynamodb', region_name=region, config=config)
# status_table = dynamodb.Table(agent_config_data['ddb_status_table'])

state_table = state_table_manager(
    agent_config_data['tasks_status_table_service'],
    str(config),
    agent_config_data['ddb_status_table'],
    agent_config_data['dynamodb_endpoint_url'],
    region)

config_cc ={
    "retries" : {
        'max_attempts': 10,
        'mode': 'adaptive'
    }
}
# dynamodb_cc = boto3.resource('dynamodb', region_name=region, config=config_cc)
# status_table_cc = dynamodb_cc.Table(agent_config_data['ddb_status_table'])

state_table_cc = state_table_manager(
    agent_config_data['tasks_status_table_service'],
    str(config_cc),
    agent_config_data['ddb_status_table'],
    agent_config_data['dynamodb_endpoint_url'],
    region)

redis_endpoint_url = agent_config_data['redis_endpoint_url']
use_ssl = True
redis_port = int(agent_config_data['redis_port'])
if agent_config_data['redis_with_ssl'].lower() == "false":
    use_ssl = False
    redis_port = int(agent_config_data['redis_port_without_ssl'])
    redis_endpoint_url = agent_config_data['redis_endpoint_url_without_ssl']

logging.info("Create redis s3 connection")
logging.info("SSL certificate :" + agent_config_data.get('redis_cert_file', 'None'))
logging.info("SSL certificate :" + agent_config_data.get('redis_key_file', 'None'))
logging.info("SSL certificate :" + agent_config_data.get('redis_ca_cert', 'None'))
stdout_iom = in_out_manager(grid_storage_service=agent_config_data['grid_storage_service'],
                            s3_bucket=agent_config_data.get('s3_bucket', None),
                            redis_url=redis_endpoint_url,
                            redis_port=redis_port,
                            s3_region=region,
                            redis_certfile=agent_config_data.get('redis_cert_file', None),
                            redis_keyfile=agent_config_data.get('redis_key_file', None),
                            redis_ca_cert=agent_config_data.get('redis_ca_cert', None),
                            use_ssl=use_ssl)

perf_tracker_pre = performance_tracker_initializer(agent_config_data["metrics_are_enabled"],
                                                   agent_config_data["metrics_pre_agent_connection_string"],
                                                   agent_config_data["metrics_grafana_private_ip"])
event_counter_pre = EventsCounter(["agent_no_messages_in_tasks_queue", "agent_failed_to_claim_ddb_task",
                                   "agent_successful_acquire_a_task", "agent_auto_throtling_event",
                                   "rc_cubic_decrease_event"])

perf_tracker_post = performance_tracker_initializer(agent_config_data["metrics_are_enabled"],
                                                    agent_config_data["metrics_post_agent_connection_string"],
                                                    agent_config_data["metrics_grafana_private_ip"])
event_counter_post = EventsCounter([
    "ddb_set_task_finished_failed", "ddb_set_task_finished_succeeded", "counter_update_ttl",
    "counter_update_ttl_failed", "counter_user_code_ret_code_failed",
    "bootstrap_failure",
    "task_exec_time_ms", "agent_total_time_ms", "str_pod_id"])


class GracefulKiller:
    """
    This class manage graceful termination when pods are terminated
    """
    kill_now = False

    def __init__(self):
        signal.signal(signal.SIGTERM, self.exit_gracefully)

    def exit_gracefully(self, signum, frame):
        """ This method is called when a signal from the kernel is sent
        Args:
            signum (int) : the id of the signal to catch
            frame (int) :
        Returns:
            Nothing
        """
        logging.info("AAAAAAAAAAAAAAA")
        self.kill_now = True
        return 0


def get_time_now_ms():
    """This function returns the time in millisecond
    Returns:
        Current Integer time in ms

    """
    return int(round(time.time() * 1000))


ttl_gen = TTLExpirationGenerator(task_ttl_refresh_interval_sec, task_ttl_expiration_offset_sec)

# {'Items': [{'session_size': Decimal('10'), 'submission_timestamp': Decimal('1612276891690'), 'task_id': 'bd88ea18-6564-11eb-b5fb-060372291b89-part007_9', 'task_status': 'processing-part007', 'task_definition': 'passed_via_storage_size_75_bytes', 'task_owner': 'htc-agent-6d54fd8dfd-7wgpk', 'heartbeat_expiration_timestamp': Decimal('1612277256'), 'session_id': 'bd88ea18-6564-11eb-b5fb-060372291b89-part007', 'sqs_handler_id': 'AQEB19gkPrI8MNJlqfdu+kH4Xr/QOnZWvH9E6qcMTVuHOEKZdhvCeGdW3opZ38k5uIngM94MEzaIZyciDpZYNuwNgXozpp2vpRz5x952R80GAt26FsPmuQQoJ6gdm7dJabHqblYghXw8r+92yTdmSZRnzAr7fpkF2f7C6LoP3AEPVa8DV/6MYbrkKBqjeQLWctQmmTwvcqVkIWJH4KqokjMx+WQt1tGHLBrdd8xPwFlb8kGgwq1d6qeu5hHkdTizoaUDqbLShSYhSWlfysZ7r9its9owIkiZiYDc5/SdPKEi2hga9SH7E1GTtKetk9mUgoH2p4lCFdH2jIDnpY5EVHoicyviCWA2AMOolDZrIeTBtPklWXOnw3Wkljr2qtWbCHS7s6R1Qpis82n+5pVJUjoNfA==', 'task_completion_timestamp': Decimal('0'), 'retries': Decimal('1'), 'parent_session_id': 'bd88ea18-6564-11eb-b5fb-060372291b89-part007'}]


def is_task_has_been_cancelled(task_id):
    """
    This function checks if the task's status is cancelled.
    It is possible that the tasks/session were cancelled by the clinet before this task has been
    picked up from SQS. Thus, we failed to ackquire this task from DDB because its status is cancelled.

    Returns:
        True if task's status is cancelled in DDB.
    """

    task_row = state_table.get_task_by_id(task_id, consistent_read=True)

    logging.info("RESP:: {}".format(task_row))

    if task_row is not None:
        if task_row['task_status'].startswith(TASK_STATUS_CANCELLED):
            return True

    return False


def try_to_acquire_a_task():
    """
    This function will fetch tasks from the SQS queue one at a time. Once is tasks is polled from the queue, then agent
    will try to acquire the task by a conditional write on dymanoDB. The tasks will be acquired if tasks in dynamoDB
    is set as "pending" and the owner is "None"

    Returns:
        A tuple containing the SQS message and the task definition

    Raises:
        Exception: occurs when task acquisition failed

    """
    global AGENT_EXEC_TIMESTAMP_MS
    logging.info("waiting for SQS message")
    message = tasks_queue.receive_message(wait_time_sec=10)
    # messages = tasks_queue.receive_messages(MaxNumberOfMessages=1, WaitTimeSeconds=10)

    task_pick_up_from_sqs_ms = get_time_now_ms()

    logging.info("try_to_acquire_a_task, message: {}".format(message))

    if "body" not in message:
        event_counter_pre.increment("agent_no_messages_in_tasks_queue")
        return None, None


    AGENT_EXEC_TIMESTAMP_MS = get_time_now_ms()

    task = json.loads(message["body"])
    logging.info("try_to_acquire_a_task, task: {}".format(task))

    # Since we read this message from the queue, now we need to associate an
    # sqs handler with this message, to be able to delete it later
    task["sqs_handle_id"] = message["properties"]["message_handle_id"]
    try:

        claim_result = state_table.claim_task_for_agent(
            task_id=task["task_id"],
            queue_handle_id=task["sqs_handle_id"],
            agent_id=SELF_ID,
            expiration_timestamp=ttl_gen.generate_next_ttl().get_next_expiration_timestamp()
            )

        logging.info("State Table claim_task_for_agent result: {}".format(claim_result))


    except StateTableException as e:

        if e.caused_by_condition or e.caused_by_throtling:

            event_counter_pre.increment("agent_failed_to_claim_ddb_task")

            if is_task_has_been_cancelled(task["task_id"]):
                logging.info("Task [{}] has been already cancelled, skipping".format(task['task_id']))

                tasks_queue.delete_message(message_handle_id=message["properties"]["message_handle_id"])
                return None, None

            else:

                time.sleep(random.randint(1, 3))
                return None, None

    except Exception as e:
        logging.error("Unexpected error in claim_task_for_agent {} [{}]".format(e, traceback.format_exc()))
        errlog.log("Unexpected error in claim_task_for_agent {} [{}]".format(
            e, traceback.format_exc()))
        raise e



        # if e.response['Error']['Code'] == 'ResourceNotFoundException':
    # If we have succesfully ackquired a message we should change its visibility timeout
    # message.change_visibility(VisibilityTimeout=agent_sqs_visibility_timeout_sec)
    tasks_queue.change_visibility(message["properties"]["message_handle_id"], visibility_timeout_sec=agent_sqs_visibility_timeout_sec)
    task["stats"]["stage3_agent_01_task_acquired_sqs_tstmp"]["tstmp"] = task_pick_up_from_sqs_ms

    task["stats"]["stage3_agent_02_task_acquired_ddb_tstmp"]["tstmp"] = get_time_now_ms()
    event_counter_pre.increment("agent_successful_acquire_a_task")

    return message, task


def process_subprocess_completion(perf_tracker, task, sqs_msg, fname_stdout, stdout=None):
    """
    This function is responsible for updating the dynamoDB item associated to the input task with the ouput of the
    execution
    Args:
        perf_tracker (utils.performance_tracker.PerformanceTracker): endpoint for sending metrics
        task (dict): the task that went to completion
        sqs_msg (Message): the SQS message associated to the completed task
        fname_stdout (file): the file  where stdout was redirected
        stdout (str): the stdout of the execution

    Returns:
        Nothing

    """
    task["stats"]["stage4_agent_01_user_code_finished_tstmp"]["tstmp"] = get_time_now_ms()

    # <1.> Store stdout/stderr into persistent storage
    if stdout is not None:
        b64output = base64.b64encode(stdout.encode("utf-8"))
        stdout_iom.put_output_from_bytes(task["task_id"], data=b64output)
    else:
        stdout_iom.put_output_from_file(task["task_id"], file_name=fname_stdout)
        # logging.info("\n===========STDOUT: ================")
        # logging.info(open(fname_stdout, "r").read())

        # ret = stdout_iom.put_error_from_file(task["task_id"], file_name=fname_stderr)

        # logging.info("\n===========STDERR: ================")
        # logging.info(open(fname_stderr, "r").read())

    task["stats"]["stage4_agent_02_S3_stdout_delivered_tstmp"]["tstmp"] = get_time_now_ms()

    count = 0
    is_update_succesfull = False
    while True:
        count += 1
        time_start_ms = get_time_now_ms()

        try:
            is_update_succesfull = state_table_cc.update_task_status_to_finished(
                task_id=task["task_id"],
                agent_id=SELF_ID
                )

            logging.info(f"Task status has been set to Finished: {task['task_id']}")

            break

        except StateTableException as e:

            if e.caused_by_throtling:

                time_end_ms = get_time_now_ms()

                logging.error(f"Agent FINISHED@StateTable #{count} Throttling for {time_end_ms - time_start_ms} ms")
                errlog.log(f"Agent FINISHED@StateTable #{count} Throttling for {time_end_ms - time_start_ms} ms")

                continue # i.e., retry again

            elif e.caused_by_condition:
                logging.error(f"Agent FINISHED@StateTable exception caused_by_condition")
                errlog.log(f"Agent FINISHED@StateTable exception caused_by_condition")

                is_update_succesfull = False

                break

        except Exception as e:
            logging.error(f"Unexpected Exception while setting tasks state to finished {e} [{traceback.format_exc()}]")
            errlog.log(f"Unexpected Exception while setting tasks state to finished {e} [{traceback.format_exc()}]")
            raise e


    if not is_update_succesfull:
        # We can get here if task has been taken over by the watchdog lambda
        # in this case we ignore results and proceed to the next task.
        event_counter_post.increment("ddb_set_task_finished_failed")
        logging.warning(f"Could not set completion state for a task {task['task_id']} to Finish")

    else:
        event_counter_post.increment("ddb_set_task_finished_succeeded")
        logging.info(
            "We have succesfully marked task as completed in dynamodb."
            " Deleting message from the SQS... for task [{}]".format(
                task["task_id"]))
        # sqs_msg.delete()
        tasks_queue.delete_message(sqs_msg["properties"]["message_handle_id"])

    logging.info("Exec time1: {} {}".format(get_time_now_ms() - AGENT_EXEC_TIMESTAMP_MS, AGENT_EXEC_TIMESTAMP_MS))
    event_counter_post.increment("agent_total_time_ms", get_time_now_ms() - AGENT_EXEC_TIMESTAMP_MS)
    event_counter_post.set("str_pod_id", SELF_ID)

    submit_post_agent_measurements(task, perf_tracker)


def submit_post_agent_measurements(task, perf=None):
    if perf is None:
        perf = perf_tracker_post
    perf.add_metric_sample(task["stats"], event_counter_post,
                           from_event="stage3_agent_02_task_acquired_ddb_tstmp",
                           to_event="stage4_agent_02_S3_stdout_delivered_tstmp")
    perf.submit_measurements()


def submit_pre_agent_measurements(task):
    perf_tracker_pre.add_metric_sample(task["stats"], event_counter_pre,
                                       from_event="stage2_sbmtlmba_02_before_batch_write_tstmp",
                                       to_event="stage3_agent_02_task_acquired_ddb_tstmp")
    perf_tracker_pre.submit_measurements()


async def do_task_local_execution_thread(
        perf_tracker, task, sqs_msg, task_def, f_stdout, f_stderr, fname_stdout):
    global execution_is_completed_flag
    xray_recorder.begin_subsegment('sub-process-1')
    command = ["./mock_compute_engine",
               task_def["worker_arguments"][0],
               task_def["worker_arguments"][1],
               task_def["worker_arguments"][2]]

    print(command)

    proc = subprocess.Popen(
        command,
        stdout=f_stdout,
        stderr=f_stderr,
        shell=False)

    while True:
        retcode = proc.poll()
        if retcode is not None:
            execution_is_completed_flag = 1  # indicate that this thread is completed

            process_subprocess_completion(perf_tracker, task, sqs_msg, fname_stdout)
            xray_recorder.end_subsegment()
            return retcode

        await asyncio.sleep(work_proc_status_pull_interval_sec)


async def do_task_local_lambda_execution_thread(perf_tracker, task, sqs_msg, task_def):
    global execution_is_completed_flag

    t_start = get_time_now_ms()

    # TODO How big of a payload we can pass here?
    payload = json.dumps(task_def).encode()
    xray_recorder.begin_subsegment('lambda')
    loop = asyncio.get_event_loop()
    response = await loop.run_in_executor(
        None, partial(
            lambda_client.invoke,
            FunctionName=os.environ['LAMBDA_FONCTION_NAME'],
            InvocationType='RequestResponse',
            Payload=payload,
            LogType='Tail'
        )
    )
    logging.info("TASK FINISHED!!!\nRESPONSE: [{}]".format(response))
    #logs = base64.b64decode(response['LogResult']).decode('utf-8')
    #logging.info("logs : {}".format(logs))

    ret_value = response['Payload'].read().decode('utf-8')
    logging.info("retValue : {}".format(ret_value))

    execution_is_completed_flag = 1

    if "BOOTSTRAP ERROR" in ret_value:
        event_counter_post.increment("bootstrap_failure", 1)
    else:
        event_counter_post.increment("task_exec_time_ms", get_time_now_ms() - t_start)

        process_subprocess_completion(perf_tracker, task, sqs_msg, None, stdout=ret_value)

    xray_recorder.end_subsegment()
    return ret_value


def update_ttl_if_required(task):
    is_refresh_successful = True

    # If this is the first time we are resetting ttl value or
    # If the next time we will come to this point ttl ticket will expire
    if ((ttl_gen.get_next_refresh_timestamp() == 0)
            or (ttl_gen.get_next_refresh_timestamp() < time.time() + work_proc_status_pull_interval_sec)):
        logging.info("***Updating TTL***")
        # event_counter_post.increment("counter_update_ttl")

        count = 0
        while True:
            count += 1
            t1 = get_time_now_ms()

            try:

                # Note, if we will timeout on DDB update operation and we have to repeat this loop iteration,
                # we will regenerate a new TTL ofset, which is what we want.
                is_refresh_successful = state_table_cc.refresh_ttl_for_ongoing_task(
                    task_id=task["task_id"],
                    agent_id=SELF_ID,
                    new_expirtaion_timestamp=ttl_gen.generate_next_ttl().get_next_expiration_timestamp()
                )

            except StateTableException as e:

                if e.caused_by_throtling:

                    t2 = get_time_now_ms()

                    logging.error(f"Agent TTL@StateTable Throttling for #{count} times for {t2 - t1} ms")
                    errlog.log(f"Agent TTL@StateTable Throttling for #{count} times for {t2-t1} ms")

                    continue
                else:
                    # Unexpected error -> Fail
                    logging.error(f"Unexpected StateTableException while refreshing TTL {e} [{traceback.format_exc()}]")
                    errlog.log(f"Unexpected StateTableException while refreshing TTL {e} [{traceback.format_exc()}]")
                    raise Exception(e)
            except Exception as e:
                logging.error(f"Unexpected Exception while refreshing TTL {e} [{traceback.format_exc()}]")
                errlog.log(f"Unexpected Exception while refreshing TTL {e} [{traceback.format_exc()}]")
                raise e

            return is_refresh_successful

    else:
        # Even if we didn't have to perform an update, return success.
        return True


async def do_ttl_updates_thread(task):
    global execution_is_completed_flag
    logging.info("START TTL-1")
    while not bool(execution_is_completed_flag):
        logging.info("Check TTL")

        ddb_res = update_ttl_if_required(task)

        if not ddb_res:
            event_counter_post.increment("counter_update_ttl_failed")
            logging.info("Could not set TTL Expiration timestamp.")
            submit_post_agent_measurements(task)
            return False

        # We are sleeping for the remaining duration of the HB interval. If for some reason we were delayed by more
        # than our interval then sleep for 0 sec and go ahead (before tasks TTL expired)
        # required_sleep = max(0,
        #                      work_proc_status_pull_interval_sec - (get_time_now_ms() - exec_loop_iter_time_ms)
        #                      / 1000.0)
        required_sleep = work_proc_status_pull_interval_sec
        await asyncio.sleep(required_sleep)


def prepare_arguments_for_execution(task):
    if task_input_passed_via_external_storage == 1:
        execution_payload = stdout_iom.get_input_to_bytes(task["task_id"])
        execution_payload = base64.b64decode(execution_payload)
    else:
        execution_payload = task["task_definition"]

    return execution_payload


async def run_task(task, sqs_msg):
    global execution_is_completed_flag
    xray_recorder.begin_segment('run_task')
    logging.info("Running Task: {}".format(task))
    xray_recorder.begin_subsegment('encoding')
    bin_protobuf = prepare_arguments_for_execution(task)
    tast_str = bin_protobuf.decode("utf-8")
    task_def = json.loads(tast_str)

    submit_pre_agent_measurements(task)
    task_id = task["task_id"]

    fname_stdout = "./stdout-{task_id}.log".format(task_id=task_id)
    fname_stderr = "./stderr-{task_id}.log".format(task_id=task_id)
    f_stdout = open(fname_stdout, "w")
    f_stderr = open(fname_stderr, "w")

    xray_recorder.end_subsegment()
    execution_is_completed_flag = 0

    task_execution = asyncio.create_task(
        do_task_local_lambda_execution_thread(perf_tracker_post, task, sqs_msg, task_def)
    )

    task_ttl_update = asyncio.create_task(do_ttl_updates_thread(task))
    await asyncio.gather(task_execution, task_ttl_update)
    f_stdout.close()
    f_stderr.close()
    xray_recorder.end_segment()
    logging.info("Finished Task: {}".format(task))
    return True


def event_loop():
    logging.info("Starting main event loop")
    killer = GracefulKiller()
    while not killer.kill_now:

        sqs_msg, task = try_to_acquire_a_task()

        if task is not None:
            asyncio.run(run_task(task, sqs_msg))
            logging.info("Back to main loop")
        else:
            timeout = random.uniform(empty_task_queue_backoff_timeout_sec, 2 * empty_task_queue_backoff_timeout_sec)
            logging.info("Could not acquire a task from the queue, backing off for {}".
                         format(timeout)
                         )
            time.sleep(timeout)
    for proc in psutil.process_iter():
        logging.info("running process : {}".format(proc.name()))
        # check whether the process name matches
        if proc.name() == 'aws-lambda-rie':
            logging.info("stop lambda emulated environment after the last request")
            proc.terminate()
    logging.info("agent and lambda gracefully stopped")


if __name__ == "__main__":

    try:

        # try_verify_credentials()
        if IS_XRAY_ENABLE == "1":
            global_sdk_config.set_sdk_enabled(True)
            xray_recorder.configure(
                service='ecs',
                context_missing='LOG_ERROR',
                daemon_address='xray-service.kube-system:2000',
                plugins=('EC2Plugin', 'ECSPlugin')
            )
            libs_to_patch = ('boto3', 'requests')
            patch(libs_to_patch)
        else:
            global_sdk_config.set_sdk_enabled(False)

        event_loop()

    except ClientError as e:
        logging.error("ClientError Agent Event Loop {} [{}] POD:{}".format(e.response['Error']['Code'], traceback.format_exc(), SELF_ID))
        errlog.log("ClientError Agent Event Loop {} [{}] POD:{}".
                   format(e.response['Error']['Code'], traceback.format_exc(), SELF_ID))
        sys.exit(1)

    except Exception as e:
        logging.error("Exception Agent Event Loop {} [{}] POD:{}".format(e, traceback.format_exc(), SELF_ID))
        errlog.log("Exception Agent Event Loop {} [{}] POD:{}".
                   format(e, traceback.format_exc(), SELF_ID))
        sys.exit(1)
