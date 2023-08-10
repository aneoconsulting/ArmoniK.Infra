# GCP Memorystore for Memcached Instance

To create a simple GCP Memorystore for Memcached Instance:

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
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.75.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_simple_memorystore_for_mecached_instance"></a> [simple\_memorystore\_for\_mecached\_instance](#module\_simple\_memorystore\_for\_mecached\_instance) | ../../../memcache | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | The GCP region to deploy the Memorystore for Memcached Instance. | `string` | `"europe-west9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_discovery_endpoint"></a> [discovery\_endpoint](#output\_discovery\_endpoint) | Endpoint for Discovery API |
| <a name="output_id"></a> [id](#output\_id) | The Memorystore instance ID. |
| <a name="output_memcache_full_version"></a> [memcache\_full\_version](#output\_memcache\_full\_version) | The full version of memcached server running on this instance. |
| <a name="output_memcache_nodes"></a> [memcache\_nodes](#output\_memcache\_nodes) | Additional information about the instance state, if available. The parameters: "node\_id", "zone", "port", "host", "state". |
<!-- END_TF_DOCS -->
