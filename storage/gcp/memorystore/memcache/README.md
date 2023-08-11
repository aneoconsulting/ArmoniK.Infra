# GCP Memorystore for Memcached instance

Memorystore for Memcached enables creating a fully-managed Memcached cluster. Before using the service, it is important to
understand some key concepts and terms. Memcached Instance represents one instance of a Memcached cluster. An instance can
be comprised of a single node or a collection of nodes. The official
documentations: [Google Memorystore for Memcached instance](https://cloud.google.com/memorystore/docs/memcached/memcached-overview)
and [Memorystore for Memcached instance configuration](https://cloud.google.com/memorystore/docs/memcached/reference/rest/v1/projects.locations.instances)
.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.75.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | ~> 4.75.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.75.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_memcache_instance.cache](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/memcache_instance) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_authorized_network"></a> [authorized\_network](#input\_authorized\_network) | TThe full name of the GCE network to connect the instance to. If not provided, 'default' will be used. | `string` | `null` | no |
| <a name="input_cpu_count"></a> [cpu\_count](#input\_cpu\_count) | Number of CPUs per node. | `number` | n/a | yes |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | A user-visible name for the instance. | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Resource labels to represent user-provided metadata. | `map(string)` | `null` | no |
| <a name="input_maintenance_policy"></a> [maintenance\_policy](#input\_maintenance\_policy) | Maintenance policy for an instance. For more information see [maintenance\_policy](https://registry.terraform.io/providers/hashicorp/google/4.77.0/docs/resources/memcache_instance). | <pre>object({<br>    day        = string<br>    duration   = string<br>    start_time = object({<br>      hours   = number<br>      minutes = number<br>      seconds = number<br>      nanos   = number<br>    })<br>  })</pre> | `null` | no |
| <a name="input_memcache_parameters"></a> [memcache\_parameters](#input\_memcache\_parameters) | User-specified parameters for this memcache instance. [Supported configuration for Memcached Instance](https://cloud.google.com/memorystore/docs/memcached/supported-memcached-configurations). | `map(string)` | `null` | no |
| <a name="input_memcache_version"></a> [memcache\_version](#input\_memcache\_version) | The major version of Memcached software. If not provided, latest supported version will be used. | `string` | `null` | no |
| <a name="input_memory_size_mb"></a> [memory\_size\_mb](#input\_memory\_size\_mb) | Memory size in Mebibytes for each memcache node. | `number` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The resource name of the instance. | `string` | n/a | yes |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | Number of nodes in the memcache instance. | `number` | n/a | yes |
| <a name="input_zones"></a> [zones](#input\_zones) | Zones where memcache nodes should be provisioned. If not provided, all zones will be used. | `set(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_discovery_endpoint"></a> [discovery\_endpoint](#output\_discovery\_endpoint) | Endpoint for Discovery API |
| <a name="output_id"></a> [id](#output\_id) | The Memorystore instance ID. |
| <a name="output_memcache_full_version"></a> [memcache\_full\_version](#output\_memcache\_full\_version) | The full version of memcached server running on this instance. |
| <a name="output_memcache_nodes"></a> [memcache\_nodes](#output\_memcache\_nodes) | Additional information about the instance state, if available. The parameters: "node\_id", "zone", "port", "host", "state". |
<!-- END_TF_DOCS -->