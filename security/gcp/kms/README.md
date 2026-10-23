# GCP Cloud KMS

Customer-managed encryption keys (CMEK) for the other modules: GKE secrets, GCS, Artifact Registry, Memorystore.

This module creates:

* A key ring.
* Crypto keys (purpose, rotation, algorithm).
* IAM roles on the key ring and on each key.

> Note: GCP never deletes key rings and keys. A destroy removes them from the state and destroys the key versions,
> and their names stay reserved.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
