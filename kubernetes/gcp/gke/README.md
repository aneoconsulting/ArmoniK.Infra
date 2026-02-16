# GKE Module

Google Kubernetes Engine (GKE) is the most scalable and fully automated Kubernetes service. This module handles opinionated
GKE cluster creation and configurations based on
the [Terraform module](https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest) of
GKE developed by Google.

This module deploy:

* Public/Private GKE standard with beta functionalities.
* Public/Private GCP Autopilot with beta functionalities.
* By default, the GCP Kubernetes cluster is autopilot and private. Otherwise, you set: `private = false`
  and/or `var.autopilot = false`.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:
:glob:

examples/**
```

