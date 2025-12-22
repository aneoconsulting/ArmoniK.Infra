#!/bin/bash

#SBATCH --job-name=ArmoniK              # nom du job
#SBATCH --nodes=2                       # Nombre total de noeuds
#SBATCH --ntasks-per-node=40            # Nombre de processus MPI par noeud
# /!\ Attention, la ligne suivante est trompeuse mais dans le vocabulaire
# de Slurm "multithread" fait bien référence à l'hyperthreading.
#SBATCH --hint=nomultithread            # 1 processus MPI par coeur physique (pas d'hyperthreading)
#SBATCH --time=00:10:00                 # Temps d’exécution maximum demande (HH:MM:SS)
#SBATCH --output=logs/ArmoniK%j.out          # Nom du fichier de sortie
#SBATCH --error=logs/ArmoniK%j.out           # Nom du fichier d'erreur (ici commun avec la sortie)

#SBATCH --account odr@cpu

env

export PROJECT=${WORK_SHARED}/Projets
export LOGS_DIR=$WORK_SHARED/armonik/$SLURM_JOB_ID/logs/$SLURM_NODEID
export DB_DIR=$WORK_SHARED/armonik/$SLURM_JOB_ID/db
export STORAGE_DIR=$JOBSCRATCH/armonik/storage

export INTALL_DIR=$WORK_SHARED/install
export PATH=$PATH:$INTALL_DIR/mongodb-linux-x86_64-rhel93-8.2.2/bin:$INTALL_DIR/mongosh-2.5.10-linux-x64/bin:$INTALL_DIR/apache-activemq-6.2.0/bin:$INTALL_DIR/jdk-21.0.8/bin

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
    -c $SINGULARITY_ALLOWED_DIR/armonik_control_0.35.0.sif

singularity/compute.sh -n 20 -s $STORAGE_DIR \
    -c /tmp/armonik/comm \
    -i $SLURMD_NODENAME \
    -l $LOGS_DIR \
    -a $SINGULARITY_ALLOWED_DIR/armonik_pollingagent_0.35.0.sif \
    -w $SINGULARITY_ALLOWED_DIR/armonik_core_htcmock_test_worker_0.35.0.sif

# run on the other nodes only (SLURM_NODEID > 0)
# todo: check things are working properly with multiple nodes
if [ "$SLURM_NNODES" -gt "1" ]; then
    expanded=$(scontrol show hostnames "$SLURM_NODELIST")
    trimmed=$(echo "$expanded" | tail -n +2)
    result=$(echo "$trimmed" | paste -sd, - | xargs scontrol show hostlists)
    echo "$result"

    srun --nodelist="$result" --nodes=$(($SLURM_NNODES - 1)) --ntasks-per-node=1 singularity/compute.sh \
        -n 80 \
        -i $SLURMD_NODENAME \
        -s $STORAGE_DIR \
        -c /tmp/armonik/comm \
        -l $LOGS_DIR \
        -a $SINGULARITY_ALLOWED_DIR/armonik_pollingagent_0.35.0.sif \
        -w $SINGULARITY_ALLOWED_DIR/armonik_core_htcmock_test_worker_0.35.0.sif
fi

sleep 10

singularity/client-htcmock.sh \
    -i $SINGULARITY_ALLOWED_DIR/armonik_core_htcmock_test_client_0.35.0.sif \
    -l $LOGS_DIR
