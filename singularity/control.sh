#!/bin/bash

# Default values
num_control=1
storage_dir="$HOME/armonik/storage"
logs_dir="$HOME/armonik/logs"
control_image="docker://dockerhubaneo/armonik_control:0.35.0"
dataplane_ip="127.0.0.1"

usage() {
  echo "Usage: $0 -n <number_of_control> -s <storage_directory> -c <communication_directory> -l <logs_directory> -c <control_image> -i <dataplane_ip>"
  echo "  -n Number of control nodes"
  echo "  -s Storage directory"
  echo "  -l Logs directory"
  echo "  -c Control image"
  echo "  -i Dataplane IP"
  exit 1
}

# Parse short options
while getopts ":n:s:c:l:i:" opt; do
  case $opt in
    n) num_control="$OPTARG" ;;
    s) storage_dir="$OPTARG" ;;
    c) control_image="$OPTARG" ;;
    l) logs_dir="$OPTARG" ;;
    i) dataplane_ip="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

OBJ_DIR="$storage_dir/local_storage"
mkdir -p $OBJ_DIR
mkdir -p $logs_dir

for i in $(seq $num_control); do
    i=$(printf "%03d" $i)

    echo "Starting control $i ..."

    nohup singularity run \
        --env-file <(cat ./singularity/activemq.env ./singularity/mongo.env ./singularity/control.env ./singularity/object-local.env) \
        --bind $OBJ_DIR:/local_storage \
        --env Amqp__Host=$dataplane_ip \
        --env MongoDB__ConnectionString="mongodb://$dataplane_ip:27017/database?directConnection=true&authSource=admin" \
        -C -e \
        --no-home \
        --no-init \
        $control_image /app/ArmoniK.Core.Control.Submitter.dll >> "$logs_dir/control$i.log" 2>&1 &
    echo $! > "$logs_dir/control$i.pid"

done


