# AWS VPC

With Amazon Virtual Private Cloud (Amazon VPC), you can launch AWS resources in a logically isolated virtual network that
you've defined. This virtual network closely resembles a traditional network that you'd operate in your own data center,
with the benefits of using the scalable infrastructure of AWS.

This module creates an AWS VPC with these constraints:

* Use all availability zones
* Create VPC flow logs in CloudWatch
* All traffic are captured in flow logs
* Enable DNS hostnames and DNS support
* Possibility to set the use of the VPC for an AWS EKS (only one EKS)

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```

