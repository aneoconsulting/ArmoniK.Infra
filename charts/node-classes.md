# Node Classes

ArmoniK pods can run on node classes that create their nodes on demand: GKE ComputeClasses today, Karpenter
NodePools later. It is off by default, like the network policies: without it every pod is rendered as
written, on whatever nodes the cluster has.

Three pieces, each opt-in:

| Piece | Where | What it does |
|---|---|---|
| Cluster | Terraform module `kubernetes/gcp/gke` | `autoscaling.default_compute_class = true`: the ComputeClass named `default` places every pod that selects none |
| Classes | chart `armonik-nodes`, one release per cluster | one ComputeClass per entry of `classes` |
| Placement | `global.armonik.nodeProvisioner: gke` and `nodeClass` on each ArmoniK component | adds the class node selector, its toleration and, on the partitions, the eviction protection |

## Model

The `default` class takes whatever selects no class: kube-system, the operators, the third-party charts,
the ArmoniK components left without `nodeClass`. Only the exceptions select a class:

- the compute plane, on `workers` (Spot first),
- the databases, on `database` (on demand, never migrated),
- anything else that needs other hardware.

The `default` class must stay untainted, since the pods that land there tolerate nothing; the chart refuses
a taint on it. The other classes are tainted by GKE on the node pools they create
(`cloud.google.com/compute-class=<class>:NoSchedule`), so only the pods that select them run there.

## Install

Order matters: a pod that selects a class waits Pending until the class exists, and with the cluster
default enabled so does every pod that selects none.

1. Cluster: `autoscaling.default_compute_class = true` on the `gke` module. `node_pools = {}` is then
   allowed, every node coming from the classes.
2. `armonik-nodes`, with `gke.defaults` set to the module output `compute_class_defaults` (the node service
   account and the boot disk key). Without the service account, GKE picks one for the node pools of the
   classes, the Compute Engine default service account unless node auto-provisioning sets another.
3. `armonik-operators`, then the ArmoniK releases, with `global.armonik.nodeProvisioner: gke`.

```yaml
# armonik release
global:
  armonik:
    nodeProvisioner: gke
compute-plane:
  partitionCommon:
    nodeClass: workers
```

## ArmoniK components

`nodeClass` sits next to `nodeSelector` on every ArmoniK pod and follows the same fallback: the component
value, else the chart-level one.

| Chart | Values |
|---|---|
| `armonik-compute-plane` | `partitionCommon.nodeClass` and `partitions.<name>.nodeClass`; `init.nodeClass` |
| `armonik-control-plane` | `nodeClass`; `metricsExporter.nodeClass`, `podDeletionCost.nodeClass`, `init.nodeClass` |
| `armonik-ingress` | `nodeClass`; `gui.nodeClass`, `loadBalancer.nodeClass` |

Partition pods also get `cluster-autoscaler.kubernetes.io/safe-to-evict: "false"` (`disruptionProtection`,
on by default), so neither consolidation nor active migration ends a running task: a node goes away once
KEDA has scaled its pods in. An annotation set in `podAnnotations` wins.

A `nodeClass` without `global.armonik.nodeProvisioner` fails the render, as does a `nodeSelector` naming
another ComputeClass than `nodeClass`.

## Third-party charts

They are not wired: they go to the `default` class. To pin one on a class, use its own values with the
label, the toleration and, for a single-instance database, the eviction protection:

```yaml
# armonik release, MongoDB on the database class
dependencies:
  mongodb:
    replsets:
      rs0:
        nodeSelector:
          cloud.google.com/compute-class: database
        tolerations:
          - key: cloud.google.com/compute-class
            operator: Equal
            value: database
            effect: NoSchedule
        annotations:
          cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
```

CloudNativePG takes the same `nodeSelector` and `tolerations` under
`dependencies.postgresql.cluster.affinity`.

## Classes

`classes.<name>.spec` is a ComputeClass spec, passed through as written. The chart only adds what the spec
leaves unset:

- `nodePoolAutoCreation.enabled: true` and `whenUnsatisfiable: DoNotScaleUp`, explicit rather than the GKE
  default, which changed in 1.33;
- on a standard class, `gke.defaults.serviceAccount` in `nodePoolConfig` and `gke.defaults.bootDiskKMSKey` in
  the `storage` of every priority rule but `nodepools` and `podFamily` ones (`priorityDefaults` has no
  `storage`). An Autopilot class (`spec.autopilot.enabled`) gets neither: it takes the node
  auto-provisioning settings of the cluster.

Values files merge the maps but replace the lists: overriding `priorities` replaces the shipped rules,
while `classes.<name>: null` drops a class. Autopilot cannot be switched on an existing class: delete it
first.

ComputeClasses are cluster-scoped: install `armonik-nodes` once per cluster.
