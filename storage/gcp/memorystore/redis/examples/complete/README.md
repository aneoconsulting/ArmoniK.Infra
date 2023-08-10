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
| <a name="module_complete_memorystore_for_redis"></a> [complete\_memorystore\_for\_redis](#module\_complete\_memorystore\_for\_redis) | ../../../redis | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.date_sh](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.timestamp](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [external_external.static_timestamp](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [google_compute_network.vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |
| [google_compute_subnetwork.subnet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | The GCP region to deploy the Memorystore | `string` | `"europe-west9"` | no |

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
