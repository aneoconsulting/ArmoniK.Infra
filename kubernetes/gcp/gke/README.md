# GCP GKE

Standard GKE cluster, built on the `private-cluster` module of
[terraform-google-modules/kubernetes-engine](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest).

This module creates:

* A GKE Standard cluster with private nodes, a public control plane endpoint, Dataplane V2 and Workload Identity by
  default.
* Its node pools and the service account of the nodes.
* Optional encryption of the Kubernetes secrets with a Cloud KMS key.

> Note: set `enable_private_endpoint = true` for a control plane reachable from the VPC only, and
> `dns_allow_external_traffic = true` to reach it from outside through the DNS endpoint with IAM authentication.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
