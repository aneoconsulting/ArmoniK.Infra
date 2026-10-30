# GKE node pool

```{warning}
This module is deprecated and will be removed. Use the `kubernetes/gcp/gke-cluster` module instead.
Every plan using this module emits a deprecation warning.
```

This module creates and manages a node pool in a Google Kubernetes Engine (GKE) cluster separately from the cluster control
plane. For more
information see the [official documentation](https://cloud.google.com/container-engine/docs/node-pools) and
the [API reference](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1beta1/projects.locations.clusters.nodePools)
.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:
:glob:

examples/**
```

