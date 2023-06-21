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
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_subnet.pod_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cidr"></a> [cidr](#input\_cidr) | Main CIDR bloc for the VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_eks_name"></a> [eks\_name](#input\_eks\_name) | Name of the EKS to be deployed in this VPC | `string` | `null` | no |
| <a name="input_enable_external_access"></a> [enable\_external\_access](#input\_enable\_external\_access) | Boolean to disable external access | `bool` | `true` | no |
| <a name="input_flow_log_cloudwatch_log_group_kms_key_id"></a> [flow\_log\_cloudwatch\_log\_group\_kms\_key\_id](#input\_flow\_log\_cloudwatch\_log\_group\_kms\_key\_id) | ARN of the KMS to encrypt/decrypt VPC flow logs | `string` | `null` | no |
| <a name="input_flow_log_cloudwatch_log_group_retention_in_days"></a> [flow\_log\_cloudwatch\_log\_group\_retention\_in\_days](#input\_flow\_log\_cloudwatch\_log\_group\_retention\_in\_days) | Number of days for retention of VPC flow logs in the CloudWatch | `number` | `null` | no |
| <a name="input_flow_log_file_format"></a> [flow\_log\_file\_format](#input\_flow\_log\_file\_format) | The format for the flow log | `string` | `"plain-text"` | no |
| <a name="input_flow_log_max_aggregation_interval"></a> [flow\_log\_max\_aggregation\_interval](#input\_flow\_log\_max\_aggregation\_interval) | The maximum interval of time during which a flow of packets is captured and aggregated into a flow log | `number` | `60` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the VPC | `string` | `""` | no |
| <a name="input_pod_subnets"></a> [pod\_subnets](#input\_pod\_subnets) | List of CIDR blocks fot Pods | `list(string)` | `[]` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | A list of private subnets inside the VPC | `list(string)` | `[]` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A list of public subnets inside the VPC | `list(string)` | `[]` | no |
| <a name="input_secondary_cidr_blocks"></a> [secondary\_cidr\_blocks](#input\_secondary\_cidr\_blocks) | List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of keys,values to tags VPC resources | `map(string)` | `{}` | no |
| <a name="input_use_karpenter"></a> [use\_karpenter](#input\_use\_karpenter) | Use Karpenter for the cluster autoscaling | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the VPC |
| <a name="output_azs"></a> [azs](#output\_azs) | A list of availability zones |
| <a name="output_cidr_block"></a> [cidr\_block](#output\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_enable_external_access"></a> [enable\_external\_access](#output\_enable\_external\_access) | Boolean to disable external access |
| <a name="output_flow_log_cloudwatch_iam_role_arn"></a> [flow\_log\_cloudwatch\_iam\_role\_arn](#output\_flow\_log\_cloudwatch\_iam\_role\_arn) | The ARN of the IAM role used when pushing logs to Cloudwatch log group |
| <a name="output_flow_log_destination_arn"></a> [flow\_log\_destination\_arn](#output\_flow\_log\_destination\_arn) | The ARN of the destination for VPC Flow Logs |
| <a name="output_flow_log_id"></a> [flow\_log\_id](#output\_flow\_log\_id) | The ID of the Flow Log resource |
| <a name="output_id"></a> [id](#output\_id) | The ID of the VPC |
| <a name="output_name"></a> [name](#output\_name) | The name of the VPC |
| <a name="output_pod_subnet_arns"></a> [pod\_subnet\_arns](#output\_pod\_subnet\_arns) | List of ARNs of Pods subnets |
| <a name="output_pod_subnets"></a> [pod\_subnets](#output\_pod\_subnets) | List of IDs of Pods subnets |
| <a name="output_pod_subnets_cidr_blocks"></a> [pod\_subnets\_cidr\_blocks](#output\_pod\_subnets\_cidr\_blocks) | List of Pods subnet CIDR blocks |
| <a name="output_private_subnet_arns"></a> [private\_subnet\_arns](#output\_private\_subnet\_arns) | List of ARNs of private subnets |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of IDs of private subnets |
| <a name="output_private_subnets_cidr_blocks"></a> [private\_subnets\_cidr\_blocks](#output\_private\_subnets\_cidr\_blocks) | List of cidr\_blocks of private subnets |
| <a name="output_public_subnet_arns"></a> [public\_subnet\_arns](#output\_public\_subnet\_arns) | List of ARNs of public subnets |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List of IDs of public subnets |
| <a name="output_public_subnets_cidr_blocks"></a> [public\_subnets\_cidr\_blocks](#output\_public\_subnets\_cidr\_blocks) | List of cidr\_blocks of public subnets |
| <a name="output_secondary_cidr_blocks"></a> [secondary\_cidr\_blocks](#output\_secondary\_cidr\_blocks) | List of secondary CIDR blocks of the VPC |
| <a name="output_tags"></a> [tags](#output\_tags) | List of tags |
| <a name="output_this"></a> [this](#output\_this) | Object VPC |
<!-- END_TF_DOCS -->
