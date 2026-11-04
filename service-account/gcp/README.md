# GCP Service Account

IAM roles for a Kubernetes service account of a GKE cluster with Workload Identity enabled.

This module creates:

* An optional Kubernetes service account (`create_service_account`).
* By default, an IAM service account with the roles, which the Kubernetes service account impersonates through its
  annotation. With `iam_service_account = false`, Workload Identity Federation for GKE grants the roles to the
  Kubernetes service account itself, with no IAM service account nor annotation.
* The IAM member holding the roles, as an output to grant roles on each resource.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 4
:glob:

examples/**
```
