# AWS ECR

To create an AWS Elasticache :

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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.61 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3.1 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.61 |
| <a name="provider_external"></a> [external](#provider\_external) | ~> 2.3.1 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_elasticache"></a> [elasticache](#module\_elasticache) | ../../../elasticache | n/a |

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
| <a name="output_endpoint_host"></a> [endpoint\_host](#output\_endpoint\_host) | AWS Elastichache (Redis) endpoint host |
| <a name="output_endpoint_port"></a> [endpoint\_port](#output\_endpoint\_port) | AWS Elastichache (Redis) endpoint port |
| <a name="output_endpoint_url"></a> [endpoint\_url](#output\_endpoint\_url) | AWS Elastichache (Redis) endpoint url |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ARN of KMS used for Elasticache |
| <a name="output_name"></a> [name](#output\_name) | Name of Elasticache cluster |
<!-- END_TF_DOCS -->

