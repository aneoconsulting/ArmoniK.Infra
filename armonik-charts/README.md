# ArmoniK with the Helm charts

Deploys ArmoniK on an existing cluster with the charts of this repository, as a layered install: the
`armonik-operators` release (External Secrets, KEDA, cert-manager, kube-prometheus-stack), then the `armonik` release
in `namespace`, which the caller creates along with the Secrets its values read.

The module sets what does not depend on the cloud:

* The layered install: the `armonik` release uses the operators of `armonik-operators` and its Prometheus,
  including the MongoDB and PostgreSQL operators unless the storage is external (`database_operators`).
* The registry of the images of ArmoniK, the operators and the monitoring, per upstream (`registries`), such as the
  prefixes of pull-through caches.
* The service accounts of the control and compute planes, by name, for the cloud roles bound to them.
* The partitions of `partitions` over the chart's own. A partition keeps one idle pod with `scale_to_zero = false`,
  which needs a chart that drops an `idleReplicaCount` not below `minReplicaCount`.
* A Grafana admin Secret, since the chart would generate a new password at every render.

The caller gives the rest as values documents (`operators_values`, `armonik_values`): storage backends, node
selection, load balancer, sizing. Resources that the releases need without referencing them, such as cloud roles or
queues, go in a `depends_on` of the module.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
