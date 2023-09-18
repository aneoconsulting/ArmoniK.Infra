<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.4.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3.1 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.10.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.22.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.4.0 |
| <a name="provider_external"></a> [external](#provider\_external) | ~> 2.3.1 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | ../../../eks | n/a |

## Resources

| Name | Type |
|------|------|
| [null_resource.timestamp](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_subnets.subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [external_external.static_timestamp](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | Profile of AWS credentials to deploy Terraform sources | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where the infrastructure will be deployed | `string` | `"eu-west-3"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Id of the cluster |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the cluster |
| <a name="output_fargate_profiles_worker_iam_role_names"></a> [fargate\_profiles\_worker\_iam\_role\_names](#output\_fargate\_profiles\_worker\_iam\_role\_names) | List of fargate profiles |
| <a name="output_issuer"></a> [issuer](#output\_issuer) | EKS Identity issuer |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Use multiple Kubernetes cluster with KUBECONFIG environment variable |
| <a name="output_managed_worker_iam_role_names"></a> [managed\_worker\_iam\_role\_names](#output\_managed\_worker\_iam\_role\_names) | EKS managed worker iam role names |
| <a name="output_self_managed_worker_iam_role_names"></a> [self\_managed\_worker\_iam\_role\_names](#output\_self\_managed\_worker\_iam\_role\_names) | EKS self managed worker iam role names |
| <a name="output_worker_iam_role_names"></a> [worker\_iam\_role\_names](#output\_worker\_iam\_role\_names) | list of the workers IAM role names |
<!-- END_TF_DOCS -->