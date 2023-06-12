<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.18.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.14.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.18.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.4.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_resource_policy.mq_logs_publishing_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_resource_policy) | resource |
| [aws_mq_broker.mq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mq_broker) | resource |
| [aws_mq_configuration.mq_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mq_configuration) | resource |
| [aws_security_group.mq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_iam_policy_document.mq_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_mq"></a> [mq](#input\_mq) | MQ Service parameters | <pre>object({<br>    engine_type             = string<br>    engine_version          = string<br>    host_instance_type      = string<br>    apply_immediately       = bool<br>    deployment_mode         = string<br>    storage_type            = string<br>    authentication_strategy = string<br>    publicly_accessible     = bool<br>    kms_key_id              = string<br>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | AWS MQ service name | `string` | `"armonik-mq"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for resource | `any` | `{}` | no |
| <a name="input_user"></a> [user](#input\_user) | User credentials | <pre>object({<br>    password = string<br>    username = string<br>  })</pre> | n/a | yes |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | AWS VPC info | <pre>object({<br>    id          = string<br>    cidr_blocks = list(string)<br>    subnet_ids  = list(string)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_activemq_endpoint_url"></a> [activemq\_endpoint\_url](#output\_activemq\_endpoint\_url) | AWS MQ (ActiveMQ) endpoint urls |
| <a name="output_engine_type"></a> [engine\_type](#output\_engine\_type) | Engine type |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ARN of KMS used for MQ |
| <a name="output_mq_name"></a> [mq\_name](#output\_mq\_name) | Name of MQ cluster |
| <a name="output_user"></a> [user](#output\_user) | Credentials of MQ user |
| <a name="output_web_url"></a> [web\_url](#output\_web\_url) | The URL of the broker's ActiveMQ Web Console |
<!-- END_TF_DOCS -->
