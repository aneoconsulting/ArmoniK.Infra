#!/bin/bash

# Default values
logs_dir="$HOME/armonik/logs"

usage() {
  echo "Usage: $0 -l <logs_directory>"
  echo "  -l Logs directory"
  exit 1
}

# Parse short options
while getopts ":l:" opt; do
  case $opt in
    l) logs_dir="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

mkdir -p $logs_dir
activemq start
