# GCP GKE Autopilot

GKE Autopilot cluster, built on the `beta-autopilot-private-cluster` module of
[terraform-google-modules/kubernetes-engine](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest).

This module creates:

* A regional GKE Autopilot cluster with private nodes, a public control plane endpoint and Workload Identity by
  default. GKE manages the nodes, sized from the resource requests of the pods.
* The service account of the nodes.
* Optional encryption of the Kubernetes secrets with a Cloud KMS key.

> Note: Autopilot rejects privileged pods, host namespaces (`hostNetwork`, `hostPID`) and `hostPath` volumes other
> than `/var/log` read-only, and bills a pod without resource requests 0.5 vCPU and 2 GiB per container.
> Use the [gke module](../gke) for a Standard cluster.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
