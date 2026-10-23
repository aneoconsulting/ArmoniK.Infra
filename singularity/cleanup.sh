#!/bin/sh

export INSTALL_DIR=$HOME/install
export PATH=$PATH:$INSTALL_DIR/mongodb-linux-x86_64-rhel93-8.2.2/bin:$INSTALL_DIR/mongosh-2.5.10-linux-x64/bin:$INSTALL_DIR/apache-activemq-6.2.0/bin

singularity/activemq-stop.sh
singularity/mongodb-stop.sh
singularity/stop-containers.sh
