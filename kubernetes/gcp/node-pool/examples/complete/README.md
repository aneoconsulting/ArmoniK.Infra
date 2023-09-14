# GKE node pool

To create a complete GKE node pool:

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
| <a name="module_gke"></a> [gke](#module\_gke) | ../../../gke | n/a |
| <a name="module_node_pool"></a> [node\_pool](#module\_node\_pool) | ../.. | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../../../../networking/gcp/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.date_sh](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.timestamp](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [external_external.static_timestamp](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_client_openid_userinfo.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_openid_userinfo) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to host the cluster in | `string` | `"europe-west9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_group_urls"></a> [instance\_group\_urls](#output\_instance\_group\_urls) | List of GKE generated instance groups |
| <a name="output_linux_instance_group_urls"></a> [linux\_instance\_group\_urls](#output\_linux\_instance\_group\_urls) | List of GKE generated instance groups for Linux node pools |
| <a name="output_linux_node_pool_names"></a> [linux\_node\_pool\_names](#output\_linux\_node\_pool\_names) | List of Linux node pool names |
| <a name="output_linux_node_pool_versions"></a> [linux\_node\_pool\_versions](#output\_linux\_node\_pool\_versions) | Linux node pool versions by node pool name |
| <a name="output_node_pool_names"></a> [node\_pool\_names](#output\_node\_pool\_names) | List of node pool names |
| <a name="output_node_pool_versions"></a> [node\_pool\_versions](#output\_node\_pool\_versions) | Node pool versions by node pool name |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | The service account to default running nodes as if not overridden in `node_pools`. |
| <a name="output_windows_instance_group_urls"></a> [windows\_instance\_group\_urls](#output\_windows\_instance\_group\_urls) | List of GKE generated instance groups for Windows node pools |
| <a name="output_windows_node_pool_names"></a> [windows\_node\_pool\_names](#output\_windows\_node\_pool\_names) | List of Windows node pool names |
| <a name="output_windows_node_pool_versions"></a> [windows\_node\_pool\_versions](#output\_windows\_node\_pool\_versions) | Windows node pool versions by node pool name |
<!-- END_TF_DOCS -->