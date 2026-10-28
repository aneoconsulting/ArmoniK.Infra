# GCP VPC

Network of a deployment, with outbound internet access through Cloud NAT and an optional subnet for GKE.

This module creates:

* A VPC (global routing by default).
* Subnets with flow logs and Private Google Access, each with or without Cloud NAT (`enable_nat`).
* An optional GKE subnet with its Pod and Service ranges, behind Cloud NAT by default so that private nodes can
  pull public images.
* One Cloud Router and NAT gateway per region that needs one.
* Optional service connection policies, which let Google services such as Memorystore for Valkey create their
  Private Service Connect endpoints in chosen subnets.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
