#!/bin/bash

# Default values
num_compute=1
storage_dir="$HOME/armonik/storage"
comm_dir="$HOME/armonik/comm"
logs_dir="$HOME/armonik/logs"
agent_image="docker://dockerhubaneo/armonik_pollingagent:0.35.0"
worker_image="docker://dockerhubaneo/armonik_core_htcmock_test_worker:0.35.0"
worker_cmd="/app/ArmoniK.Samples.HtcMock.Server.dll"
dataplane_ip="127.0.0.1"

usage() {
  echo "Usage: $0 -n <number_of_compute> -s <storage_directory> -c <communication_directory> -l <logs_directory> -a <agent_image> -w <worker_image> -m <worker_command> -i <dataplane_ip>"
  echo "  -n Number of compute nodes"
  echo "  -s Storage directory"
  echo "  -c Communication directory"
  echo "  -l Logs directory"
  echo "  -a Agent image"
  echo "  -w Worker image"
  echo "  -m Worker command"
  echo "  -i Dataplane IP"
  exit 1
}

# Parse short options
while getopts ":n:s:c:l:a:w:m:i:" opt; do
  case $opt in
    n) num_compute="$OPTARG" ;;
    s) storage_dir="$OPTARG" ;;
    c) comm_dir="$OPTARG" ;;
    l) logs_dir="$OPTARG" ;;
    a) agent_image="$OPTARG" ;;
    w) worker_image="$OPTARG" ;;
    m) worker_cmd="$OPTARG" ;;
    i) dataplane_ip="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

OBJ_DIR="$storage_dir/local_storage"
mkdir -p $OBJ_DIR
mkdir -p $logs_dir

for i in $(seq $num_compute); do
    i=$(printf "%03d" $i)

    SOCK_DIR="$comm_dir/compute$i/sock"
    DATA_DIR="$comm_dir/compute$i/data"

    mkdir -p $SOCK_DIR
    mkdir -p $DATA_DIR

    echo "Starting compute $i ..."

    nohup singularity run \
        --env-file singularity/compute.env \
        --bind $SOCK_DIR:/cache,$DATA_DIR:/data \
        -C -e \
        --no-home \
        --no-init \
        $worker_image $worker_cmd >> "$logs_dir/worker$i.log" 2>&1 &
    echo $! > "$logs_dir/worker$i.pid"


    nohup singularity run \
        --bind $SOCK_DIR:/cache,$DATA_DIR:/data,$OBJ_DIR:/local_storage \
        --env ASPNETCORE_URLS="http://+:5$i" \
        --env Amqp__Host=$dataplane_ip \
        --env MongoDB__ConnectionString="mongodb://$dataplane_ip:27017/database?directConnection=true&authSource=admin" \
        --env-file <(cat singularity/activemq.env singularity/mongo.env singularity/compute.env singularity/object-local.env singularity/agent.env) \
        -C -e \
        --no-home \
        --no-init \
        $agent_image /app/ArmoniK.Core.Compute.PollingAgent.dll >> "$logs_dir/agent$i.log" 2>&1 &
    echo $! > "$logs_dir/agent$i.pid"
done
