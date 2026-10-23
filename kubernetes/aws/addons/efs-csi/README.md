# AWS EFS CSI driver  

```{warning}
This module is deprecated and will be removed. The `kubernetes/aws/eks` module deploys the EFS CSI driver itself,
configured through its `efs_csi` input. Every plan using this module emits a deprecation warning.
```
Amazon Elastic File System (Amazon EFS) provides serverless, fully elastic file storage so that you can share file data without provisioning or managing storage capacity and performance. The Amazon EFS Container Storage Interface (CSI) driver provides a CSI interface that allows Kubernetes clusters running on AWS to manage the lifecycle of Amazon EFS file systems. This topic shows you how to deploy the Amazon EFS CSI driver to your Amazon EKS cluster.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```

