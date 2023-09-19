# AWS Amazon MQ

To create a simple AWS Amazon MQ using RabbitMQ engine :

```bash
terraform init
terraform plan
terraform apply
```

To delete all resource:

```bash
terraform destroy
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.4.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3.1 |
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
| <a name="module_rabbitmq"></a> [rabbitmq](#module\_rabbitmq) | ../../../../mq | n/a |

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
| <a name="output_engine_type"></a> [engine\_type](#output\_engine\_type) | Engine type |
| <a name="output_name"></a> [name](#output\_name) | Name of Amazon MQ cluster |
| <a name="output_password"></a> [password](#output\_password) | AWS Amazon MQ password |
| <a name="output_rabbitmq_endpoint_host"></a> [rabbitmq\_endpoint\_host](#output\_rabbitmq\_endpoint\_host) | AWS Amazon MQ endpoint host |
| <a name="output_rabbitmq_endpoint_port"></a> [rabbitmq\_endpoint\_port](#output\_rabbitmq\_endpoint\_port) | AWS Amazon MQ endpoint port |
| <a name="output_rabbitmq_endpoint_url"></a> [rabbitmq\_endpoint\_url](#output\_rabbitmq\_endpoint\_url) | AWS Amazon MQ endpoint urls |
| <a name="output_username"></a> [username](#output\_username) | AWS Amazon MQ username |
| <a name="output_web_url"></a> [web\_url](#output\_web\_url) | Web URL for Amazon Rabbitmq |
<!-- END_TF_DOCS -->