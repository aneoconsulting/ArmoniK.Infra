#!/bin/bash

# Default values
database_directory="$HOME/armonik/db"
logs_dir="$HOME/armonik/logs"

usage() {
  echo "Usage: $0 -d <database_directory> -l <logs_directory>"
  echo "  -d Database directory"
  echo "  -l Logs directory"
  exit 1
}

# Parse short options
while getopts ":d:l:" opt; do
  case $opt in
    d) database_directory="$OPTARG" ;;
    l) logs_dir="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

mkdir -p $logs_dir
mkdir -p $database_directory
nohup mongod --bind_ip_all --replSet rs0 --dbpath $database_directory >> "$logs_dir/mongodb.log" 2>&1 &

sleep 10

mongosh mongodb://127.0.0.1:27017/database --eval 'rs.initiate({_id: "rs0", members: [{_id: 0, host: "127.0.0.1:27017"}]})'
