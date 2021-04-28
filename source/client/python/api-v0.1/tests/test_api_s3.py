# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

import os
import sys
import base64
import uuid
import boto3
import pytest
import sure  # noqa: F401
import responses
import json
from moto import mock_cognitoidp
from moto import mock_s3
from moto.s3.responses import DEFAULT_REGION_NAME

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from api.connector import AWSConnector  # noqa: E402
from utils.dynamodb_common import TASK_STATUS_FINISHED  # noqa: E402


@pytest.fixture
def mock_cognitoidp_client():
    """return a client mocking the connection with AWS Cognito IDP

    Returns:
        object: the mocked connection
    """
    with mock_cognitoidp():
        conn = boto3.client("cognito-idp", region_name="eu-west-1")
        yield conn


@pytest.fixture
def mock_s3_resource():
    """return a client mocking the connection with AWS S3

    Returns:
        object: the mocked connection
    """
    with mock_s3():
        conn = boto3.resource("s3", region_name=DEFAULT_REGION_NAME)
        yield conn


@pytest.fixture
def mock_user_pool(mock_cognitoidp_client):
    """Create a mocked cognito user pool used to instantiate a mock AWS Connector

    Args:
        mock_cognitoidp_client: a mocked Cognito IDP client

    Returns:
        dict: containing a mocked user pool id (key: UserPoolId) and a mocked user pool client id (key: UserPoolClientId)

    """
    name = str(uuid.uuid4())
    value = str(uuid.uuid4())
    result_user_pool = mock_cognitoidp_client.create_user_pool(PoolName=name, LambdaConfig={"PreSignUp": value})

    client_name = str(uuid.uuid4())
    value = str(uuid.uuid4())
    user_pool_id = result_user_pool["UserPool"]["Id"]
    result_user_pool_client = mock_cognitoidp_client.create_user_pool_client(
        UserPoolId=user_pool_id,
        ClientName=client_name,
        CallbackURLs=[value]
    )
    return {
        "UserPoolId": user_pool_id,
        "UserPoolClientId": result_user_pool_client["UserPoolClient"]["ClientId"],
    }


@pytest.fixture
def mock_s3_bucket_dataplane(mock_s3_resource):
    """Create a mocked S3 bucket for the dataplane

    Args:
        mock_s3_resource: the mocked S3 resource.

    Returns:
        Nothing

    """
    mock_s3_resource.create_bucket(Bucket='test_bucket')


@pytest.fixture
def mocked_responses_submit():
    """Create a mocker for http connection made through the requests library

    Yields:
        The mocked http connection
    """
    with responses.RequestsMock() as rsps:
        rsps.add(
            responses.POST, "https://publicapi.eu-west-1.amazonaws.com/submit",
            json={
                "session_id": "1234567890123",
                "task_ids": []
            }, status=200,
            content_type='application/json')

        yield rsps


@pytest.fixture
def mocked_responses_get():
    """Create a mocker for http connection made through the requests library

    Yields:
        The mocked http connection
    """
    with responses.RequestsMock() as rsps:
        rsps.add(
            responses.GET, "https://publicapi.eu-west-1.amazonaws.com/result",
            json={
                "metadata": {
                    "tasks_in_response": 2
                },
                TASK_STATUS_FINISHED: ["test1", "test2"],
                TASK_STATUS_FINISHED + '_OUTPUT': [
                    "NoResult1",
                    "NoResult2"
                ]
            }, status=200,
            content_type='application/json')
        yield rsps


@pytest.fixture
def test_init_connector(mock_cognitoidp_client, mock_user_pool, mock_s3_resource, mock_s3_bucket_dataplane):
    """Test the creation of a connector and share it with the rest the test suite

    Args:
      mock_cognitoidp_client (object): ab object mocking the connection with Cognito IDP

    Returns:
        AWSConnector: an instance of HTC Grid connector
    """
    mock_agent_config = {
        "region": DEFAULT_REGION_NAME,
        "grid_storage_service": "S3",
        "s3_bucket": "test_bucket",
        "redis_url": "redis_url.eu-west-1.amazonaws.com",
        "public_api_gateway_url": "https://publicapi.eu-west-1.amazonaws.com",
        "private_api_gateway_url": "https://privateapi.eu-west-1.amazonaws.com",
        "api_gateway_key": "mocked_api_key_for_private_api",
        "user_pool_id": mock_user_pool["UserPoolId"],
        "cognito_userpool_client_id": mock_user_pool["UserPoolClientId"],
        "dynamodb_results_pull_interval_sec": 1,
        "task_input_passed_via_external_storage": 1
    }
    connector = AWSConnector()
    connector.init(
        mock_agent_config,
        username="test_user",
        password="test_password",
        cognitoidp_client=mock_cognitoidp_client,
        s3_custom_resource=mock_s3_resource)
    return connector


@pytest.fixture
def test_generate_one_task(test_init_connector):
    """Test the creation of one task

    Args:
      test_init_connector (object): an HTC grid connector

    Returns:
        dict: return a task to be reused by other test
    """
    tasks = [
        {
            "worker_arguments": "1000 1 1"
        }
    ]
    generated_task = test_init_connector.generate_user_task_json(tasks)
    generated_task.should.have.key("session_id")
    generated_task.should.have.key("scheduler_data")
    generated_task["scheduler_data"].should.have.key("task_timeout_sec")
    generated_task["scheduler_data"].should.have.key("retry_count")
    generated_task["scheduler_data"].should.have.key("tstamp_api_grid_connector_ms").which.should.be.equal(0)
    generated_task["scheduler_data"].should.have.key("tstamp_agent_read_from_sqs_ms").which.should.be.equal(0)
    generated_task.should.have.key("stats")
    generated_task.should.have.key("tasks_list")
    generated_task["tasks_list"].should.have.key("tasks").which.should.have.length_of(1)
    return generated_task


@pytest.fixture
def output_for_get_result(test_init_connector):
    """Generate fake output for testing the get method of the AWSConnector

    Args:
        test_init_connector: mock the AWS Connector

    Returns:
        Nothing

    """
    output1 = "OK1"
    test_init_connector.in_out_manager.put_output_from_bytes("test1", data=base64.b64encode(output1.encode("utf-8")))
    output2 = "OK2"
    test_init_connector.in_out_manager.put_output_from_bytes("test2", data=base64.b64encode(output2.encode("utf-8")))


def test_send(test_init_connector, test_generate_one_task, mocked_responses_submit):
    """Test the send function of the AWSConnector class

    Args:
        test_init_connector(connector.AWSConnector): a connection to the HTC grid
        test_generate_one_task(dict):
        mocked_responses:

    Returns:
        Nothing
    """
    # testing tasks generation
    tasks = [
        {
            "worker_arguments": "1000 1 1"
        }
    ]
    # check response of the requests
    resp = test_init_connector.send(tasks)
    resp.should.have.key("session_id").which.should.equal("1234567890123")
    resp.should.have.key("task_ids").which.should.have.length_of(0)
    # check  content sent to API Gateway
    mocked_responses_submit.calls.should.have.length_of(1)
    submitted_session = mocked_responses_submit.calls[0].request.params
    submitted_session.should.have.key("submission_content")
    submitted_content = json.loads(base64.urlsafe_b64decode(
        test_init_connector.in_out_manager.get_payload_to_utf8_string(submitted_session["submission_content"])).decode(
        "utf-8"))
    # submitted_content = json.loads(base64.urlsafe_b64decode(mocked_responses.calls[0].request.params).decode('utf-8'))
    submitted_content.should.have.key("session_id").which.should.equal(submitted_session["submission_content"])
    submitted_content.should.have.key("scheduler_data").which.should.equal(test_generate_one_task["scheduler_data"])
    submitted_content.should.have.key("stats")
    submitted_content["stats"].should.have.key("stage1_grid_api_01_task_creation_tstmp") \
        .which.should.have.key("label").which.should.equal(" ")
    submitted_content["stats"].should.have.key("stage1_grid_api_01_task_creation_tstmp") \
        .which.should.have.key("tstmp")
    submitted_content["stats"].should.have.key("stage1_grid_api_02_task_submission_tstmp") \
        .which.should.have.key("label").which.should.equal("upload_data_to_storage")
    submitted_content["stats"].should.have.key("stage1_grid_api_02_task_submission_tstmp") \
        .which.should.have.key("tstmp")
    submitted_content["stats"].should.have.key("stage2_sbmtlmba_01_invocation_tstmp") \
        .should.equal(test_generate_one_task["stats"]["stage2_sbmtlmba_01_invocation_tstmp"])
    submitted_content["stats"].should.have.key("stage2_sbmtlmba_02_before_batch_write_tstmp") \
        .should.equal(test_generate_one_task["stats"]["stage2_sbmtlmba_02_before_batch_write_tstmp"])
    submitted_content["stats"].should.have.key("stage3_agent_01_task_acquired_sqs_tstmp") \
        .should.equal(test_generate_one_task["stats"]["stage3_agent_01_task_acquired_sqs_tstmp"])
    submitted_content["stats"].should.have.key("stage3_agent_02_task_acquired_ddb_tstmp") \
        .should.equal(test_generate_one_task["stats"]["stage3_agent_02_task_acquired_ddb_tstmp"])
    submitted_content["stats"].should.have.key("stage4_agent_01_user_code_finished_tstmp") \
        .should.equal(test_generate_one_task["stats"]["stage4_agent_01_user_code_finished_tstmp"])
    submitted_content["stats"].should.have.key("stage4_agent_02_S3_stdout_delivered_tstmp") \
        .should.equal(test_generate_one_task["stats"]["stage4_agent_02_S3_stdout_delivered_tstmp"])
    submitted_content.should.have.key("tasks_list").which.should.equal(test_generate_one_task["tasks_list"])


def test_get_results(test_init_connector, mocked_responses_get, output_for_get_result):
    submission_result = {
        "task_ids": [
            "123456789",
            "123345769"
        ],
        "session_id": "12984908349"
    }
    result = test_init_connector.get_results(submission_result)
    # check output of the method
    result.should.have.key("metadata").which.should.be.equal({"tasks_in_response": 2})
    result.should.have.key("finished").which.should.be.equal(["test1", "test2"])
    result.should.have.key("finished_OUTPUT").which.should.be.equal(["OK1", "OK2"])
    # check content sent to API Gateway
    mocked_responses_get.calls.should.have.length_of(1)
    get_result_request = mocked_responses_get.calls[0].request.params
    get_result_request.should.have.key("submission_content")
    submitted_content = json.loads(base64.urlsafe_b64decode(get_result_request["submission_content"]).decode("utf-8"))
    submitted_content.should.be.equal({"session_id": "12984908349"})
