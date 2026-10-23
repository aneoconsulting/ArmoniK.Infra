# ArmoniK on Jean Zay (Singularity + Slurm)

Scripts to run ArmoniK (core 0.41.2) with the HtcMock sample on the Jean Zay supercomputer, without Kubernetes:
MongoDB and ActiveMQ run as plain processes, the ArmoniK components run as Singularity containers.

## Prerequisites

### Container images

Images are built as `.sif` files, which works on a Jean Zay login node, then added to the container manager so that
they land in `$SINGULARITY_ALLOWED_DIR` (copies are per user):

```bash
module load singularity
cd $WORK_SHARED/images
for image in armonik_control armonik_pollingagent armonik_core_htcmock_test_worker armonik_core_htcmock_test_client; do
    singularity build ${image}_0.41.2.sif docker://dockerhubaneo/${image}:0.41.2
    idrcontmgr cp ${image}_0.41.2.sif
done
idrcontmgr ls
```

Docker Hub sometimes answers `Forbidden` while pulling a layer: running the build again is enough.

### MongoDB, ActiveMQ and Java

The binaries are installed into `$WORK_SHARED/install`, and `deploy.slurm.sh` expects these exact directories:

- `mongodb-linux-x86_64-rhel93-8.2.2` (RedHat/CentOS 9 build) and `mongosh-2.5.10-linux-x64` (MongoDB Shell);
- `apache-activemq-6.2.0`, from the Unix binaries of the
  [download page](https://activemq.apache.org/components/classic/download/) (the links are dead);
- `jdk-21.0.8`, used by ActiveMQ.

### Slurm output directory

The Slurm output goes to `logs/ArmoniK<job id>.out`, relative to the submission directory, and Slurm does not create
it: `mkdir -p $WORK_SHARED/Projets/logs` once.

## Usage

Submit from `$WORK_SHARED/Projets`, in a login shell: `sbatch` hands the environment of the submitting shell over to
the job, which needs `$WORK_SHARED` and the `module` command. The scripts set no Slurm account, so pass your project's
CPU account (`<project>@cpu`) on the command line:

```bash
cd $WORK_SHARED/Projets
sbatch -A <project>@cpu singularity/run.slurm.sh
```

Both job scripts source `deploy.slurm.sh`: the first node runs ActiveMQ, MongoDB, the control plane and 20 computes;
every other node runs 80 computes through `srun`. The client starts once the control plane and all the agents are
ready (`wait-ready.sh`).

`run.local.sh` runs everything on a single machine, `cleanup.sh` stops it.

### Test scenarios

`test.slurm.sh` deploys ArmoniK once and runs the HtcMock scenarios given as arguments, `a-smoke b-compute c-data` by
default:

```bash
sbatch -A <project>@cpu singularity/test.slurm.sh                  # functional tests
sbatch -A <project>@cpu singularity/test.slurm.sh a-smoke d-bench  # throughput benchmark, a-smoke warms up
```

| Scenario    | What it checks                                                                                              |
|-------------|-------------------------------------------------------------------------------------------------------------|
| `a-smoke`   | 500 instantaneous tasks, with the default client options of `htcmock.env`                                   |
| `b-compute` | 2000 tasks really waiting for their computation time, 30 min spread over all the agents                     |
| `c-data`    | 1 MiB outputs and 10 MiB of memory per task, the outputs go through the object storage shared by the nodes |
| `d-bench`   | 20000 instantaneous tasks, so that the graph generation and the tail become negligible                     |

A scenario `<name>` is the client configuration `scenarios/<name>.env` (`a-smoke` uses `htcmock.env`), so adding one
only takes a new file. Each one is stopped after 300 s. The client checks its result, and the Slurm output ends with
a summary: PASS/FAIL with the throughput of each session, the number of tasks per session and status in MongoDB, and
the number of tasks per node.

HtcMock ignores some of its options unless told otherwise: `EnableFastCompute`, `EnableSmallOutput` and
`EnableUseLowMem` default to `true`, which makes the tasks ignore `TotalCalculationTime`, `DataSize` (in bytes) and
`MemorySize` (in KiB). Set them to `false` to really wait, output data or allocate memory.

### Data and logs

MongoDB and ActiveMQ keep their data in `/dev/shm` on the first node, that is in RAM: compute nodes have no local disk,
`/tmp` is a 150 MB tmpfs and Lustre makes every fsync a network round trip. The data is lost, and removed, when the
job ends. `DB_DIR` and `ACTIVEMQ_DATA` override the locations, e.g.
`sbatch --export=ALL,DB_DIR=$WORK_SHARED/armonik/db ...`; directories outside `/dev/shm` are kept. The object storage
stays on Lustre (`$JOBSCRATCH`) since the agents of every node read and write it.

Logs are written to `$WORK_SHARED/armonik/<job id>/logs`:

- one sub-directory per node with the logs of the control plane, agents and workers;
- one sub-directory per scenario with its `client.log` (`client.log` at the top for `run.slurm.sh`);
- `mongodb.log`, `activemq.log` (copied at the end of the job) and, for the test job, `top-services.log` which samples
  the CPU usage of MongoDB, ActiveMQ and the control plane.

### Upgrading ArmoniK

Build and copy the images of the new version, set `ARMONIK_VERSION` in `deploy.slurm.sh`, and update the default
images of `compute.sh`, `control.sh` and `client-htcmock.sh` (used by `run.local.sh`).

## Known pitfalls

- Under `srun`, the step ends when `compute.sh` returns and Slurm kills its containers: `compute.sh -W` waits for them.
- An `srun` step only gets the CPUs it asks for: `--cpus-per-task` gives it the whole node.
- Each .NET process watches its configuration files with inotify, and nodes limit a user to 128 instances: file
  watching is disabled in `compute.env`.
