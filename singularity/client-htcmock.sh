#!/bin/bash

# Default values
client_image="docker://dockerhubaneo/armonik_core_htcmock_test_client:0.41.2"
logs_dir="$HOME/armonik/logs"
env_file="singularity/htcmock.env"

usage() {
  echo "Usage: $0 -i <client_image> -l <logs_directory> -f <env_file>"
  echo "  -i Client image"
  echo "  -l Logs directory"
  echo "  -f HtcMock options as an environment file"
  exit 1
}

# Parse short options
while getopts ":i:l:f:" opt; do
  case $opt in
    i) client_image="$OPTARG" ;;
    l) logs_dir="$OPTARG" ;;
    f) env_file="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

singularity run \
    -C -e \
    --env-file "$env_file" \
    --env GrpcClient__Endpoint=http://localhost:1080 \
    --no-home \
    --no-init \
    $client_image /app/ArmoniK.Samples.HtcMock.Client.dll >> "$logs_dir/client.log" 2>&1
