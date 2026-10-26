# GCP Service Account

IAM roles for a Kubernetes service account through Workload Identity Federation for GKE, with no GCP service account.

This module creates:

* The IAM member of the Kubernetes service account, as an output to grant roles on each resource.
* Optional IAM roles on the whole project.

> Note: the GKE cluster must have Workload Identity enabled. The Kubernetes service account needs no annotation and
> may be created after the roles are granted.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
