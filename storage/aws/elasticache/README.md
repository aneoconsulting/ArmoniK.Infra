# AWS Elasticache

Amazon ElastiCache is a fully managed, Redis- and Memcached-compatible service delivering real-time, cost-optimized performance for modern applications. ElastiCache scales to hundreds of millions of operations per second with microsecond response time, and offers enterprise-grade security and reliability.  

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.61 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.61 |

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
| <a name="input_adapter_absolute_path"></a> [adapter\_absolute\_path](#input\_adapter\_absolute\_path) | The adapter's absolute path | `string` | `"/adapters/object/redis/ArmoniK.Core.Adapters.Redis.dll"` | no |
| <a name="input_adapter_class_name"></a> [adapter\_class\_name](#input\_adapter\_class\_name) | Name of the adapter's class | `string` | `"ArmoniK.Core.Adapters.Redis.ObjectBuilder"` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Specifies whether any modifications are applied immediately, or during the next maintenance window | `bool` | `false` | no |
| <a name="input_automatic_failover_enabled"></a> [automatic\_failover\_enabled](#input\_automatic\_failover\_enabled) | Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails | `bool` | `false` | no |
| <a name="input_client_name"></a> [client\_name](#input\_client\_name) | Name of the redis client | `string` | `"ArmoniK.Core"` | no |
| <a name="input_data_tiering_enabled"></a> [data\_tiering\_enabled](#input\_data\_tiering\_enabled) | Enables data tiering | `bool` | `false` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | Name of the cache engine to be used for the clusters in this replication group | `string` | `"redis"` | no |
| <a name="input_engine_log"></a> [engine\_log](#input\_engine\_log) | Engine type of the logs | `string` | `""` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Version number of the cache engine to be used for the cache clusters in this replication group | `string` | `"engine_version_actual"` | no |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | Name of the instance | `string` | `"ArmoniKRedis"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | AWS KMS key id | `string` | `null` | no |
| <a name="input_log_kms_key_id"></a> [log\_kms\_key\_id](#input\_log\_kms\_key\_id) | AWS KMS key id for logs | `string` | `null` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | Number of days of the retention of the logs | `number` | `0` | no |
| <a name="input_max_memory_samples"></a> [max\_memory\_samples](#input\_max\_memory\_samples) | Number of samples to check for every eviction | `number` | `null` | no |
| <a name="input_multi_az_enabled"></a> [multi\_az\_enabled](#input\_multi\_az\_enabled) | Specifies whether to enable Multi-AZ Support for the replication group | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | AWS Elasticache service name | `string` | `"armonik-elasticache"` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | Instance class to be used | `string` | `"cache.r4.large"` | no |
| <a name="input_num_cache_clusters"></a> [num\_cache\_clusters](#input\_num\_cache\_clusters) | Number of cache clusters (primary and replicas) this replication group will have | `number` | `1` | no |
| <a name="input_object_storage_adapter"></a> [object\_storage\_adapter](#input\_object\_storage\_adapter) | Name of the adapter's | `string` | `"ArmoniK.Adapters.Redis.ObjectStorage"` | no |
| <a name="input_preferred_cache_cluster_azs"></a> [preferred\_cache\_cluster\_azs](#input\_preferred\_cache\_cluster\_azs) | List of EC2 availability zones in which the replication group's cache clusters will be created | `list(string)` | `[]` | no |
| <a name="input_slow_log"></a> [slow\_log](#input\_slow\_log) | Slow log | `string` | `""` | no |
| <a name="input_ssl_option"></a> [ssl\_option](#input\_ssl\_option) | Ssl option | `string` | `"true"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for resource | `any` | `{}` | no |
| <a name="input_vpc_cidr_blocks"></a> [vpc\_cidr\_blocks](#input\_vpc\_cidr\_blocks) | AWS VPC cidr block | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | AWS VPC id | `string` | n/a | yes |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | AWS VPC subnet ids | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint_host"></a> [endpoint\_host](#output\_endpoint\_host) | AWS Elastichache (Redis) endpoint host |
| <a name="output_endpoint_port"></a> [endpoint\_port](#output\_endpoint\_port) | AWS Elastichache (Redis) endpoint port |
| <a name="output_endpoint_url"></a> [endpoint\_url](#output\_endpoint\_url) | AWS Elastichache (Redis) endpoint url |
| <a name="output_env"></a> [env](#output\_env) | Elements to be set as environment variables |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ARN of KMS used for Elasticache |
| <a name="output_name"></a> [name](#output\_name) | Name of Elasticache cluster |
<!-- END_TF_DOCS -->
