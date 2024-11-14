# AWS Amazon MQ

Amazon MQ is a managed message broker service for Apache ActiveMQ and RabbitMQ that streamlines setup, operation, and management of message brokers on AWS. With a few steps, Amazon MQ can provision your message broker with support for software version upgrades.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.61 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.7.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.61 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.7.1 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_resource_policy.mq_logs_publishing_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_resource_policy) | resource |
| [aws_mq_broker.mq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mq_broker) | resource |
| [aws_mq_configuration.mq_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mq_configuration) | resource |
| [aws_security_group.mq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [kubernetes_secret.activemq_user_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_iam_policy_document.mq_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adapter_absolute_path"></a> [adapter\_absolute\_path](#input\_adapter\_absolute\_path) | The adapter's absolut path | `string` | `"/adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll"` | no |
| <a name="input_adapter_class_name"></a> [adapter\_class\_name](#input\_adapter\_class\_name) | Name of the adapter's class | `string` | `"ArmoniK.Core.Adapters.Amqp.QueueBuilder"` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Specifies whether any broker modifications are applied immediately, or during the next maintenance window | `bool` | `false` | no |
| <a name="input_authentication_strategy"></a> [authentication\_strategy](#input\_authentication\_strategy) | AWS MQ authentication strategy | `string` | `"simple"` | no |
| <a name="input_deployment_mode"></a> [deployment\_mode](#input\_deployment\_mode) | AWS MQ deployment mode | `string` | `"SINGLE_INSTANCE"` | no |
| <a name="input_engine_type"></a> [engine\_type](#input\_engine\_type) | AWS MQ engine type | `string` | n/a | yes |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | AWS MQ engine version | `string` | n/a | yes |
| <a name="input_host_instance_type"></a> [host\_instance\_type](#input\_host\_instance\_type) | AWS MQ host instance type | `string` | `"mq.m5.xlarge"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | AWS KMS key id | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | AWS MQ service name | `string` | `"armonik-mq"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK storage resources | `string` | `"armonik"` | no |
| <a name="input_password"></a> [password](#input\_password) | User password | `string` | `null` | no |
| <a name="input_publicly_accessible"></a> [publicly\_accessible](#input\_publicly\_accessible) | Whether to enable connections from applications outside of the VPC that hosts the broker's subnets | `bool` | `null` | no |
| <a name="input_queue_storage_adapter"></a> [queue\_storage\_adapter](#input\_queue\_storage\_adapter) | Name of the adapter's | `string` | `"ArmoniK.Adapters.Amqp.ObjectStorage"` | no |
| <a name="input_scheme"></a> [scheme](#input\_scheme) | The scheme for the AMQP | `string` | `"AMQPS"` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | AWS MQ storage type | `string` | `"efs"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for resource | `any` | `{}` | no |
| <a name="input_username"></a> [username](#input\_username) | User name | `string` | `null` | no |
| <a name="input_vpc_cidr_blocks"></a> [vpc\_cidr\_blocks](#input\_vpc\_cidr\_blocks) | AWS VPC cidr block | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | AWS VPC id | `string` | n/a | yes |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | AWS VPC subnet ids | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint_host"></a> [endpoint\_host](#output\_endpoint\_host) | AWS MQ endpoint host |
| <a name="output_endpoint_port"></a> [endpoint\_port](#output\_endpoint\_port) | AWS MQ endpoint port |
| <a name="output_endpoint_url"></a> [endpoint\_url](#output\_endpoint\_url) | AWS MQ endpoint urls |
| <a name="output_engine_type"></a> [engine\_type](#output\_engine\_type) | Engine type |
| <a name="output_env"></a> [env](#output\_env) | Elements to be set as environment variables |
| <a name="output_env_secret"></a> [env\_secret](#output\_env\_secret) | Secrets to be set as environment variables |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ARN of KMS used for MQ |
| <a name="output_name"></a> [name](#output\_name) | Name of MQ cluster |
| <a name="output_password"></a> [password](#output\_password) | Password of Amazon MQ |
| <a name="output_username"></a> [username](#output\_username) | Username of Amazon MQ |
| <a name="output_web_url"></a> [web\_url](#output\_web\_url) | The URL of the broker's Amazon MQ Web Console |
<!-- END_TF_DOCS -->
