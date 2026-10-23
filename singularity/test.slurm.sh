#!/bin/bash

#SBATCH --job-name=ArmoniK-test         # nom du job
#SBATCH --nodes=2                       # Nombre total de noeuds
#SBATCH --ntasks-per-node=40            # Nombre de processus MPI par noeud
# /!\ Attention, la ligne suivante est trompeuse mais dans le vocabulaire
# de Slurm "multithread" fait bien référence à l'hyperthreading.
#SBATCH --hint=nomultithread            # 1 processus MPI par coeur physique (pas d'hyperthreading)
#SBATCH --time=00:15:00                 # Temps d’exécution maximum demande (HH:MM:SS)
#SBATCH --output=logs/ArmoniK%j.out          # Nom du fichier de sortie
#SBATCH --error=logs/ArmoniK%j.out           # Nom du fichier d'erreur (ici commun avec la sortie)

# Runs several HtcMock scenarios on a single ArmoniK deployment, then summarizes them.
# Scenarios are given as arguments (default: a-smoke b-compute c-data), each one is singularity/scenarios/<name>.env
# except a-smoke which uses the default singularity/htcmock.env, e.g.:
#   sbatch -A <project>@cpu singularity/test.slurm.sh a-smoke d-bench

source singularity/deploy.slurm.sh

set +x

# run_scenario <name> <env_file>: the client exits with 0 when it gets the expected result
run_scenario() {
    local name=$1
    local env_file=$2
    mkdir -p $LOGS_DIR/$name
    timeout 300 singularity/client-htcmock.sh \
        -i $SINGULARITY_ALLOWED_DIR/armonik_core_htcmock_test_client_${ARMONIK_VERSION}.sif \
        -l $LOGS_DIR/$name \
        -f $env_file
    local rc=$?
    if [ $rc -eq 0 ]; then status=PASS; else status="FAIL (rc=$rc)"; fi
    summary="$summary$name: $status$(grep -h -o '"sessionThroughput":[0-9.]*,"nTasks":[0-9]*,"timespan":"[^"]*"' $LOGS_DIR/$name/client.log)\n"
}

# sample the CPU usage of the shared services on the first node
pids=$(echo $(pgrep -u $USER -x mongod) $(pgrep -u $USER -f "java.*activemq" | head -1) $(pgrep -u $USER -f "dotnet .*Submitter.dll") | tr " " ",")
top -b -d 2 -p "$pids" | grep --line-buffered -E "^ *[0-9]+ " | awk '{ print strftime("%T"), $0; fflush() }' > $LOGS_DIR/top-services.log &
top_pid=$!

summary=""
for name in ${@:-a-smoke b-compute c-data}; do
    if [ "$name" = a-smoke ]; then
        run_scenario $name singularity/htcmock.env
    else
        run_scenario $name singularity/scenarios/$name.env
    fi
done
kill $top_pid

echo "===== Scenarios"
printf "$summary"

echo "===== Tasks per session and status"
mongosh --quiet mongodb://127.0.0.1:27017/database --eval '
const names = ["Unspecified", "Creating", "Submitted", "Dispatched", "Completed", "Error", "Timeout", "Cancelling",
               "Cancelled", "Processing", "Processed", "Retried", "Pending", "Paused"];
db.TaskData.aggregate([
  { $group: { _id: { session: "$SessionId", status: "$Status" }, n: { $sum: 1 } } },
  { $sort: { "_id.session": 1, "_id.status": 1 } },
]).forEach(d => print(d._id.session, names[d._id.status] ?? d._id.status, d.n));'

echo "===== Tasks per node"
for dir in $LOGS_DIR/*/; do
    [ -n "$(ls $dir/agent*.log 2>/dev/null)" ] || continue
    echo "$(basename $dir): $(cat $dir/agent*.log | grep -c 'Process task output is')"
done
