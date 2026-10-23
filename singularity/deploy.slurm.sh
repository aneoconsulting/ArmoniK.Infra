# Deploys ArmoniK over the nodes of the Slurm allocation and waits for it to be ready.
# Sourced by the job scripts, which must be submitted from $WORK_SHARED/Projets.

env

export ARMONIK_VERSION=0.41.2
export PROJECT=${WORK_SHARED}/Projets
export LOGS_DIR=$WORK_SHARED/armonik/$SLURM_JOB_ID/logs
export DB_DIR=$WORK_SHARED/armonik/$SLURM_JOB_ID/db
export STORAGE_DIR=$JOBSCRATCH/armonik/storage

export INSTALL_DIR=$WORK_SHARED/install
export PATH=$PATH:$INSTALL_DIR/mongodb-linux-x86_64-rhel93-8.2.2/bin:$INSTALL_DIR/mongosh-2.5.10-linux-x64/bin:$INSTALL_DIR/apache-activemq-6.2.0/bin:$INSTALL_DIR/jdk-21.0.8/bin

cd $PROJECT

module purge
module load singularity

set -x

# run on the first node only (SLURM_NODEID == 0)
singularity/activemq-start.sh -l $LOGS_DIR
singularity/mongodb-start.sh -d $DB_DIR -l $LOGS_DIR

sleep 15

singularity/control.sh -n 1 -s $STORAGE_DIR \
    -i $SLURMD_NODENAME \
    -l $LOGS_DIR \
    -c $SINGULARITY_ALLOWED_DIR/armonik_control_${ARMONIK_VERSION}.sif

singularity/compute.sh -n 20 -s $STORAGE_DIR \
    -c /tmp/armonik/comm \
    -i $SLURMD_NODENAME \
    -l $LOGS_DIR \
    -a $SINGULARITY_ALLOWED_DIR/armonik_pollingagent_${ARMONIK_VERSION}.sif \
    -w $SINGULARITY_ALLOWED_DIR/armonik_core_htcmock_test_worker_${ARMONIK_VERSION}.sif

# run on the other nodes only (SLURM_NODEID > 0)
# todo: check things are working properly with multiple nodes
if [ "$SLURM_NNODES" -gt "1" ]; then
    expanded=$(scontrol show hostnames "$SLURM_NODELIST")
    trimmed=$(echo "$expanded" | tail -n +2)
    result=$(echo "$trimmed" | paste -sd, - | xargs scontrol show hostlists)
    echo "$result"

    srun --nodelist="$result" --nodes=$(($SLURM_NNODES - 1)) --ntasks-per-node=1 --cpus-per-task=$SLURM_NTASKS_PER_NODE singularity/compute.sh \
        -n 80 \
        -i $SLURMD_NODENAME \
        -s $STORAGE_DIR \
        -c /tmp/armonik/comm \
        -l $LOGS_DIR \
        -a $SINGULARITY_ALLOWED_DIR/armonik_pollingagent_${ARMONIK_VERSION}.sif \
        -w $SINGULARITY_ALLOWED_DIR/armonik_core_htcmock_test_worker_${ARMONIK_VERSION}.sif \
        -W &
fi

# wait for the control plane and all the agents to be started before running the client
until (echo > /dev/tcp/127.0.0.1/1080) 2>/dev/null; do sleep 2; done
singularity/wait-ready.sh -n 20 -i $SLURMD_NODENAME
for node in $trimmed; do
    singularity/wait-ready.sh -n 80 -i $node
done
