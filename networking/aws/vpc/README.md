<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.0.0 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 5.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_security_group_rule.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_vpc_peering_connection.peering](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | AWS VPC service name | `string` | `"armonik-vpc"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for resource | `any` | `{}` | no |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | Parameters of AWS VPC | <pre>object({<br>    cluster_name                                    = string<br>    main_cidr_block                                 = string<br>    pod_cidr_block_private                          = list(string)<br>    private_subnets                                 = list(string)<br>    public_subnets                                  = list(string)<br>    enable_private_subnet                           = bool<br>    enable_nat_gateway                              = bool<br>    single_nat_gateway                              = bool<br>    flow_log_cloudwatch_log_group_kms_key_id        = string<br>    flow_log_cloudwatch_log_group_retention_in_days = number<br>    peering = object({<br>      enabled      = bool<br>      peer_vpc_ids = list(string)<br>    })<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cidr_block"></a> [cidr\_block](#output\_cidr\_block) | ID of the VPC |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | EKS cluster name |
| <a name="output_id"></a> [id](#output\_id) | ID of the VPC |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ARN of KMS used for VPC |
| <a name="output_pod_cidr_block_private"></a> [pod\_cidr\_block\_private](#output\_pod\_cidr\_block\_private) | CIDR Pod private subnets |
| <a name="output_pods_subnet_ids"></a> [pods\_subnet\_ids](#output\_pods\_subnet\_ids) | ids of the private subnet created |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | ids of the private subnet created |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | ids of the public subnet created |
| <a name="output_selected"></a> [selected](#output\_selected) | Created VPC |
<!-- END_TF_DOCS -->
