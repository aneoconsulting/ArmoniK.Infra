# ArmoniK on Jean Zay (Singularity + Slurm)

Scripts to run ArmoniK (core 0.41.2) with the HtcMock sample on the Jean Zay supercomputer, without Kubernetes:
MongoDB and ActiveMQ run as plain processes, the ArmoniK components run as Singularity containers.

## Prerequisites

### Container images

Images must be built locally as `.sif` files, then added to the container manager so that they land in
`$SINGULARITY_ALLOWED_DIR` (copies are per user):

```bash
singularity build armonik_pollingagent_0.41.2.sif docker://dockerhubaneo/armonik_pollingagent:0.41.2
module load singularity
idrcontmgr cp armonik_pollingagent_0.41.2.sif
idrcontmgr ls
```

The job needs `armonik_control`, `armonik_pollingagent`, `armonik_core_htcmock_test_worker` and
`armonik_core_htcmock_test_client`.

### MongoDB

Binaries copied into `$WORK_SHARED/install`, using the RedHat/CentOS 9 builds. Same for `mongosh` (MongoDB Shell).

### ActiveMQ

[Binaries download page](https://activemq.apache.org/components/classic/download/) (the links are dead), Unix
binaries, also installed into `$WORK_SHARED/install` together with a JDK 21.

## Usage

Submit from `$WORK_SHARED/Projets`: the Slurm output path (`logs/`) is relative to the submission directory. The
script sets no Slurm account, so pass your project's CPU account (`<project>@cpu`) on the command line:

```bash
cd $WORK_SHARED/Projets
sbatch -A <project>@cpu singularity/run.slurm.sh
```

The first node runs ActiveMQ, MongoDB, the control plane and 20 computes; every other node runs 80 computes through
`srun`. The client starts once the control plane and all the agents are ready (`wait-ready.sh`). Logs are written to
`$WORK_SHARED/armonik/<job id>/logs`, one sub-directory per node.

`run.local.sh` runs everything on a single machine, `cleanup.sh` stops it.

## Known pitfalls

- Under `srun`, the step ends when `compute.sh` returns and Slurm kills its containers: `compute.sh -W` waits for them.
- An `srun` step only gets the CPUs it asks for: `--cpus-per-task` gives it the whole node.
- Each .NET process watches its configuration files with inotify, and nodes limit a user to 128 instances: file
  watching is disabled in `compute.env`.
