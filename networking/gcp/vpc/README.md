# GCP VPC

With Google Virtual Private Cloud networks (Google VPC), you can launch GCP resources in a logically isolated virtual network that
you've defined. This virtual network closely resembles a traditional network that you'd operate in your own data center,
with the benefits of using the scalable infrastructure of GCP.

This module creates a GCP VPC with these constraints:

* By default, the VPC is global
* All subnets are in the same region chosen by user
* List of subnets can be created, each with or without outbound internet access through Cloud NAT
* A subnet for VPC-native Kubernetes clusters can be created, with Cloud NAT by default so that private nodes can pull
  public images
* All created subnets are of purpose `PRIVATE_RFC_1918`
* Create subnet flow logs in Stackdriver
* All traffic are captured in flow logs
* Subnetwork without external IP addresses can access Google APIs and services by using Private Google Access
* Cloud NAT is outbound only: no subnet gets public IP addresses or inbound access

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```

