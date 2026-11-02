# GCP GKE Cluster

GKE Standard cluster on a single `google_container_cluster` resource, tuned for batch workloads that scale fast.

This module creates:

* A GKE cluster on Dataplane V2 with private nodes, no public IP endpoint, Workload Identity, Cloud DNS, NodeLocal
  DNSCache, image streaming, the Gateway API, the default ComputeClass and the performance HPA profile by default.
  `networking.dataplane_v2 = false` keeps the legacy datapath (kube-proxy), with Calico enforcing the network policies
  when `networking.network_policy` is set.
* Its static node pools (a small `system` pool by default), the service account of the nodes, and optionally node
  auto-provisioning.
* Optional encryption of the Kubernetes secrets and of the node boot disks with Cloud KMS keys.
* Optionally a kubeconfig file, written with `gcloud`.

> Note: the control plane is reachable from the VPC only by default. `control_plane.dns_allow_external_traffic = true`
> opens its DNS endpoint to IAM-authenticated callers from anywhere; `control_plane.enable_private_endpoint = false`
> adds a public IP endpoint, reachable from the `control_plane.authorized_networks` only. Autopilot is not a mode of this
> module: Pods that select the `autopilot` or `autopilot-spot` ComputeClass run in Autopilot mode (GKE 1.34.1-gke.1829001
> and later), and custom ComputeClasses, applied apart from this module, create node pools on demand.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
