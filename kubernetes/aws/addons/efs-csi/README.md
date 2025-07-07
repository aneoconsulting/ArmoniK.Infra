# AWS EFS CSI driver  
Amazon Elastic File System (Amazon EFS) provides serverless, fully elastic file storage so that you can share file data without provisioning or managing storage capacity and performance. The Amazon EFS Container Storage Interface (CSI) driver provides a CSI interface that allows Kubernetes clusters running on AWS to manage the lifecycle of Amazon EFS file systems. This topic shows you how to deploy the Amazon EFS CSI driver to your Amazon EKS cluster.
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.61 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.10.1, < 3.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.22.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.61 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.10.1, < 3.0.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.22.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.efs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.efs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.efs_csi](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_service_account.efs_csi_driver](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_csi_driver_image_pull_secrets"></a> [csi\_driver\_image\_pull\_secrets](#input\_csi\_driver\_image\_pull\_secrets) | CSI driver image pull secrets | `string` | n/a | yes |
| <a name="input_csi_driver_name"></a> [csi\_driver\_name](#input\_csi\_driver\_name) | CSI driver name | `string` | n/a | yes |
| <a name="input_csi_driver_namespace"></a> [csi\_driver\_namespace](#input\_csi\_driver\_namespace) | CSI driver namespace | `string` | n/a | yes |
| <a name="input_csi_driver_node_selector"></a> [csi\_driver\_node\_selector](#input\_csi\_driver\_node\_selector) | CSI driver node selector | `any` | n/a | yes |
| <a name="input_csi_driver_repository"></a> [csi\_driver\_repository](#input\_csi\_driver\_repository) | CSI driver repository | `string` | n/a | yes |
| <a name="input_csi_driver_version"></a> [csi\_driver\_version](#input\_csi\_driver\_version) | CSI driver version | `string` | n/a | yes |
| <a name="input_efs_csi_image"></a> [efs\_csi\_image](#input\_efs\_csi\_image) | EFS CSI image | `string` | n/a | yes |
| <a name="input_efs_csi_tag"></a> [efs\_csi\_tag](#input\_efs\_csi\_tag) | EFS CSI tag | `string` | n/a | yes |
| <a name="input_external_provisioner_image"></a> [external\_provisioner\_image](#input\_external\_provisioner\_image) | External provisioner image | `string` | n/a | yes |
| <a name="input_external_provisioner_tag"></a> [external\_provisioner\_tag](#input\_external\_provisioner\_tag) | External provisioner tag | `string` | n/a | yes |
| <a name="input_livenessprobe_image"></a> [livenessprobe\_image](#input\_livenessprobe\_image) | Livenessprobe image | `string` | n/a | yes |
| <a name="input_livenessprobe_tag"></a> [livenessprobe\_tag](#input\_livenessprobe\_tag) | Livenessporbe tag | `string` | n/a | yes |
| <a name="input_node_driver_registrar_image"></a> [node\_driver\_registrar\_image](#input\_node\_driver\_registrar\_image) | Node driver registrar image | `string` | n/a | yes |
| <a name="input_node_driver_registrar_tag"></a> [node\_driver\_registrar\_tag](#input\_node\_driver\_registrar\_tag) | Node driver registrar tag | `string` | n/a | yes |
| <a name="input_oidc_arn"></a> [oidc\_arn](#input\_oidc\_arn) | Cluster oidc arn | `string` | n/a | yes |
| <a name="input_oidc_url"></a> [oidc\_url](#input\_oidc\_url) | Cluster oidc url | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for EFS CSI driver | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_efs_csi_id"></a> [efs\_csi\_id](#output\_efs\_csi\_id) | EFS CSI Id |
<!-- END_TF_DOCS -->
