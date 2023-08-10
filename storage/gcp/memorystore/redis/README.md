# GCP Memorystore for Redis

Google Memorystore for Redis provides a fully-managed service that is powered by the Redis in-memory data store to build
application caches that provide sub-millisecond data access. The official
documentations: [Google Memorystore](https://cloud.google.com/memorystore/docs/redis/)
and [Memorystore configuration](https://cloud.google.com/memorystore/docs/redis/reference/rest/v1/projects.locations.instances#Instance.FIELDS.redis_configs).

This module creates a Memorystore with these possibilities :

* Configure the persistence for the Memorystore.
* Configure the maintenance policy for the Memorystore.
* The Transit encryption is set to true by default.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.75.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.75.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_redis_instance.cache](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/redis_instance) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auth_enabled"></a> [auth\_enabled](#input\_auth\_enabled) | Indicates whether OSS Redis AUTH is enabled for the instance. If set to true AUTH is enabled on the instance. | `bool` | `false` | no |
| <a name="input_authorized_network"></a> [authorized\_network](#input\_authorized\_network) | The full name of the Google Compute Engine network to which the instance is connected. If left unspecified, the default network will be used. | `string` | `null` | no |
| <a name="input_connect_mode"></a> [connect\_mode](#input\_connect\_mode) | The connection mode of the Redis instance. Can be either DIRECT\_PEERING or PRIVATE\_SERVICE\_ACCESS. The default connect mode if not provided is DIRECT\_PEERING. | `string` | `"DIRECT_PEERING"` | no |
| <a name="input_customer_managed_key"></a> [customer\_managed\_key](#input\_customer\_managed\_key) | Default encryption key to apply to the Redis instance. Defaults to null (Google-managed). | `string` | `null` | no |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | An arbitrary and optional user-provided name for the instance. | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | The resource labels to represent user provided metadata. | `map(string)` | `null` | no |
| <a name="input_locations"></a> [locations](#input\_locations) | The zones where the instance will be provisioned. If two zones are given, HA is enabled. | `set(string)` | `[]` | no |
| <a name="input_maintenance_policy"></a> [maintenance\_policy](#input\_maintenance\_policy) | The maintenance policy for an instance. For more information see [maintenance\_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/redis_instance). | <pre>object({<br>    day = string<br>    start_time = object({<br>      hours   = number<br>      minutes = number<br>      seconds = number<br>      nanos   = number<br>    })<br>  })</pre> | `null` | no |
| <a name="input_memory_size_gb"></a> [memory\_size\_gb](#input\_memory\_size\_gb) | Redis memory size in GiB. | `number` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The ID of the instance or a fully qualified identifier for the instance. | `string` | n/a | yes |
| <a name="input_persistence_config"></a> [persistence\_config](#input\_persistence\_config) | The Redis persistence configuration parameters. For more information see [persistence\_config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/redis_instance). | <pre>object({<br>    persistence_mode        = string<br>    rdb_snapshot_period     = string<br>    rdb_snapshot_start_time = string<br>  })</pre> | `null` | no |
| <a name="input_read_replicas_mode"></a> [read\_replicas\_mode](#input\_read\_replicas\_mode) | Read replicas mode. | `string` | `"READ_REPLICAS_DISABLED"` | no |
| <a name="input_redis_configs"></a> [redis\_configs](#input\_redis\_configs) | The Redis configuration parameters. See documentation in [Supported Redis configuration](https://cloud.google.com/memorystore/docs/redis/supported-redis-configurations). | `map(any)` | `{}` | no |
| <a name="input_redis_version"></a> [redis\_version](#input\_redis\_version) | The version of Redis software. | `string` | `null` | no |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | The number of replicas. | `number` | `null` | no |
| <a name="input_reserved_ip_range"></a> [reserved\_ip\_range](#input\_reserved\_ip\_range) | The CIDR range of internal addresses that are reserved for this instance. | `string` | `null` | no |
| <a name="input_secondary_ip_range"></a> [secondary\_ip\_range](#input\_secondary\_ip\_range) | Optional. Additional IP range for node placement. Required when enabling read replicas on an existing instance. See [secondary\_ip\_range](https://registry.terraform.io/providers/hashicorp/google/4.77.0/docs/resources/redis_instance). | `string` | `null` | no |
| <a name="input_tier"></a> [tier](#input\_tier) | The service tier of the instance. | `string` | `"BASIC"` | no |
| <a name="input_transit_encryption_mode"></a> [transit\_encryption\_mode](#input\_transit\_encryption\_mode) | The TLS mode of the Redis instance, If not provided, TLS is enabled for the instance. | `string` | `"SERVER_AUTHENTICATION"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_auth_string"></a> [auth\_string](#output\_auth\_string) | AUTH String set on the instance. This field will only be populated if auth\_enabled is true. |
| <a name="output_current_location_id"></a> [current\_location\_id](#output\_current\_location\_id) | The current zone where the Redis endpoint is placed. |
| <a name="output_host"></a> [host](#output\_host) | The IP address of the instance. |
| <a name="output_id"></a> [id](#output\_id) | The Memorystore instance ID. |
| <a name="output_nodes"></a> [nodes](#output\_nodes) | Info per node |
| <a name="output_persistence_iam_identity"></a> [persistence\_iam\_identity](#output\_persistence\_iam\_identity) | Cloud IAM identity used by import/export operations. Format is 'serviceAccount:'. May change over time |
| <a name="output_port"></a> [port](#output\_port) | The port number of the exposed Redis endpoint. |
| <a name="output_read_endpoint"></a> [read\_endpoint](#output\_read\_endpoint) | The IP address of the exposed readonly Redis endpoint. |
| <a name="output_read_endpoint_port"></a> [read\_endpoint\_port](#output\_read\_endpoint\_port) | The port number of the exposed readonly redis endpoint. Standard tier only. Write requests should target 'port'. |
| <a name="output_region"></a> [region](#output\_region) | The region the instance lives in. |
| <a name="output_server_ca_certs"></a> [server\_ca\_certs](#output\_server\_ca\_certs) | List of server CA certificates for the instance |
<!-- END_TF_DOCS -->
