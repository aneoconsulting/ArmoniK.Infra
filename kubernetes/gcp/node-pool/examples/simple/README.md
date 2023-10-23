# GKE node pool

To create a simple GKE node pool:

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
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.75.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.21.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.75.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gke"></a> [gke](#module\_gke) | ../../../gke | n/a |
| <a name="module_node_pool"></a> [node\_pool](#module\_node\_pool) | ../../../node-pool | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../../../../networking/gcp/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

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