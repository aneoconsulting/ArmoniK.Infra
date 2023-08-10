# GCP Memorystore for Redis

To create a simple GCP Memorystore:

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
| <a name="module_simple_memorystore_for_redis"></a> [simple\_memorystore\_for\_redis](#module\_simple\_memorystore\_for\_redis) | ../../../redis | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | The GCP region to deploy the Memorystore | `string` | `"europe-west9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_current_location_id"></a> [current\_location\_id](#output\_current\_location\_id) | The current zone where the Redis endpoint is placed. |
| <a name="output_host"></a> [host](#output\_host) | The IP address of the instance. |
| <a name="output_id"></a> [id](#output\_id) | The Memorystore instance ID. |
| <a name="output_nodes"></a> [nodes](#output\_nodes) | Info per node |
| <a name="output_port"></a> [port](#output\_port) | The port number of the exposed Redis endpoint. |
| <a name="output_region"></a> [region](#output\_region) | The region the instance lives in. |
<!-- END_TF_DOCS -->
