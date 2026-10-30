# GCP VPC

Network of a deployment, with outbound internet access through Cloud NAT and an optional subnet for GKE.

This module creates:

* A VPC (global routing by default).
* Subnets with flow logs and Private Google Access; public subnets (`public_access`) reach the internet through Cloud NAT.
* An optional GKE subnet with its Pod and Service ranges, optionally behind Cloud NAT (`public_access`) so that
  private nodes can pull public images.
* One Cloud Router and NAT gateway per region with a public subnet.
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
