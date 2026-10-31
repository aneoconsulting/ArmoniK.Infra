# GCP Private Service Access

Private IP addresses in the VPC for Google managed services, such as Cloud SQL.

This module creates:

* An internal IP range reserved for the service producers.
* The VPC peering with `servicenetworking.googleapis.com`.

> Note: with `deletion_policy = "REMOVE_PEERING"`, an ephemeral environment can delete its VPC even while a
> producer still holds the connection.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
