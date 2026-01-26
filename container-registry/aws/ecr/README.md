# AWS ECR

Amazon Elastic Container Registry (Amazon ECR) is a fully managed container registry offering high-performance hosting, so you can reliably deploy application images and artifacts anywhere. 

This module creates AWS ECR with these possibilities :

* Enable or disable mutability
* Enable or disable the scan on push
* Enable or disable the force delete
* Choose the encryption type 
* Set ECR policy on only pull accounts and/or push and pull accounts
* Set a lifecycle policy

This module must be used with these constraints:

* Use the same availability zone to all the repositories
* Give the image name and the tag of the all repositories

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```

