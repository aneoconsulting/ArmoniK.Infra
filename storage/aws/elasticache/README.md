<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.18.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.18.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_engine_log"></a> [engine\_log](#module\_engine\_log) | ../../../monitoring/aws/cloudwatch-log-group | n/a |
| <a name="module_slow_log"></a> [slow\_log](#module\_slow\_log) | ../../../monitoring/aws/cloudwatch-log-group | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_elasticache_parameter_group.elasticache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_parameter_group) | resource |
| [aws_elasticache_replication_group.elasticache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group) | resource |
| [aws_elasticache_subnet_group.elasticache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |
| [aws_security_group.elasticache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_elasticache"></a> [elasticache](#input\_elasticache) | Parameters of Elasticache | <pre>object({<br>    engine                      = string<br>    engine_version              = string<br>    node_type                   = string<br>    apply_immediately           = bool<br>    multi_az_enabled            = bool<br>    automatic_failover_enabled  = bool<br>    num_cache_clusters          = number<br>    preferred_cache_cluster_azs = list(string)<br>    data_tiering_enabled        = bool<br>    log_retention_in_days       = number<br>    cloudwatch_log_groups = object({<br>      slow_log   = string<br>      engine_log = string<br>    })<br>    encryption_keys = object({<br>      kms_key_id     = string<br>      log_kms_key_id = string<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | AWS Elasticache service name | `string` | `"armonik-elasticache"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for resource | `any` | `{}` | no |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | AWS VPC info | <pre>object({<br>    id          = string<br>    cidr_blocks = list(string)<br>    subnet_ids  = list(string)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_elasticache_name"></a> [elasticache\_name](#output\_elasticache\_name) | Name of Elasticache cluster |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ARN of KMS used for Elasticache |
| <a name="output_redis_endpoint_url"></a> [redis\_endpoint\_url](#output\_redis\_endpoint\_url) | AWS Elasticahe (Redis) endpoint urls |
<!-- END_TF_DOCS -->