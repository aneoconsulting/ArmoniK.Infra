#!/bin/bash

# Default values
num_compute=1
host="127.0.0.1"
timeout=300

usage() {
  echo "Usage: $0 -n <number_of_compute> -i <host> -t <timeout>"
  echo "  -n Number of compute (agents) to wait for on the host"
  echo "  -i Host running the agents"
  echo "  -t Timeout in seconds"
  exit 1
}

# Parse short options
while getopts ":n:i:t:" opt; do
  case $opt in
    n) num_compute="$OPTARG" ;;
    i) host="$OPTARG" ;;
    t) timeout="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

deadline=$((SECONDS + timeout))

for i in $(seq $num_compute); do
    i=$(printf "%03d" $i)
    until curl -sf -o /dev/null "http://$host:5$i/startup"; do
        if [ $SECONDS -ge $deadline ]; then
            echo "Timeout waiting for agent $i on $host" >&2
            exit 1
        fi
        sleep 2
    done
done

echo "$num_compute agents ready on $host"
