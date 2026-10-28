# GCP GKE

GKE cluster, Standard or Autopilot, built on the `private-cluster` and `beta-autopilot-private-cluster` modules of
[terraform-google-modules/kubernetes-engine](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest).

This module creates:

* A GKE cluster with private nodes, a public control plane endpoint, Dataplane V2 and Workload Identity by default:
  Standard, or Autopilot with `autopilot = true`.
* The node pools of a Standard cluster, and the service account of the nodes.
* Optional encryption of the Kubernetes secrets with a Cloud KMS key.

> Note: set `enable_private_endpoint = true` for a control plane reachable from the VPC only, and
> `dns_allow_external_traffic = true` to reach it from outside through the DNS endpoint with IAM authentication.

> Note: the variables and outputs that apply to one mode only say so in their description ("Standard only",
> "Autopilot only") and are ignored, or null, in the other. An Autopilot cluster is always regional, and rejects
> privileged pods, host namespaces (`hostNetwork`, `hostPID`) and `hostPath` volumes other than `/var/log` read-only.
> It bills a pod without resource requests 0.5 vCPU and 2 GiB per container.

> Note: the Autopilot module needs the `google-beta` provider, which Terraform then installs whatever the mode. Without a
> `provider "google-beta"` block, it takes its project, region and credentials from the environment only.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
