#!/bin/bash

# Default values
client_image="docker://dockerhubaneo/armonik_core_htcmock_test_client:0.35.0"
logs_dir="$HOME/armonik/logs"

usage() {
  echo "Usage: $0 -i <client_image> -l <logs_directory>"
  echo "  -i Client image"
  echo "  -l Logs directory"
  exit 1
}

# Parse short options
while getopts ":i:l:" opt; do
  case $opt in
    i) client_image="$OPTARG" ;;
    l) logs_dir="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

singularity run \
    -C -e \
    --env HtcMock__NTasks=500 \
    --env HtcMock__TotalCalculationTime=00:10:00.100  \
    --env HtcMock__DataSize=1 \
    --env HtcMock__MemorySize=1 \
    --env HtcMock__SubTasksLevels=3 \
    --env HtcMock__Partition=default \
    --env GrpcClient__Endpoint=http://localhost:1080 \
    --no-home \
    --no-init \
    $client_image /app/ArmoniK.Samples.HtcMock.Client.dll >> "$logs_dir/client.log" 2>&1

