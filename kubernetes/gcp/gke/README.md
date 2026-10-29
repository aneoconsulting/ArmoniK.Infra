# GCP GKE

GKE cluster, Standard or Autopilot, on a single `google_container_cluster` resource.

This module creates:

* A GKE cluster with private nodes, no public IP endpoint, Dataplane V2 and Workload Identity by default: Standard, or
  Autopilot with `autopilot = true`.
* The node pools of a Standard cluster, and the service account of the nodes.
* Optional encryption of the Kubernetes secrets with a Cloud KMS key.

> Note: the control plane is reachable from the VPC only by default. `dns_allow_external_traffic = true` opens its DNS
> endpoint to IAM-authenticated callers from anywhere; `enable_private_endpoint = false` adds a public IP endpoint,
> reachable from the `master_authorized_networks` only. The variables and outputs that apply to one mode only say so
> in their description ("Standard only"). An Autopilot cluster is always regional, and rejects privileged pods, host
> namespaces and `hostPath` volumes other than `/var/log` read-only.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
