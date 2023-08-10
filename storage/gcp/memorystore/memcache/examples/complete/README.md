# GCP Memorystore for Memcache Instance

To create a simple GCP Memorystore for Memcache Instance:

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
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3.1 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.75.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | ~> 2.3.1 |
| <a name="provider_google"></a> [google](#provider\_google) | ~> 4.75.0 |
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.4.0 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.2.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_complete_memorystore_for_memcached_instance"></a> [complete\_memorystore\_for\_memcached\_instance](#module\_complete\_memorystore\_for\_memcached\_instance) | ../../../memcache | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.date_sh](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.timestamp](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [external_external.static_timestamp](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [google_compute_network.vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | The GCP region to deploy the Memorystore for Memcached Instance | `string` | `"europe-west9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_discovery_endpoint"></a> [discovery\_endpoint](#output\_discovery\_endpoint) | Endpoint for Discovery API |
| <a name="output_id"></a> [id](#output\_id) | The Memorystore instance ID. |
| <a name="output_memcache_full_version"></a> [memcache\_full\_version](#output\_memcache\_full\_version) | The full version of memcached server running on this instance. |
| <a name="output_memcache_nodes"></a> [memcache\_nodes](#output\_memcache\_nodes) | Additional information about the instance state, if available. The parameters: "node\_id", "zone", "port", "host", "state". |
<!-- END_TF_DOCS -->
