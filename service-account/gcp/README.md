# GCP service account for Pods

This module facilitates the creation of a GCP service account assigned with the "workLoadIdentityUser" role, along with
other necessary roles. Additionally, it establishes a Kubernetes service account that assumes the identity of the GCP
service account. This Kubernetes service account is meant to be associated with the pods within the GKE cluster.

This module performs the following actions:
* Create a GCP service account assigned with "workLoadIdentityUser" role.
* Add a list of IAM roles for the GCP service account.
* Create a kubernetes service account associated with the GCP service account.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 4
:glob:

examples/**
```

