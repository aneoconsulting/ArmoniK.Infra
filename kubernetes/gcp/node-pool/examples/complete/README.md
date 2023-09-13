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
Copyright 2020 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.75.0, < 5.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | 2.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.75.0, < 5.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gke"></a> [gke](#module\_gke) | terraform-google-modules/kubernetes-engine/google | 27.0.0 |
| <a name="module_node_pool"></a> [node\_pool](#module\_node\_pool) | ../.. | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../../../../networking/gcp/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/2.4.0/docs/resources/file) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name for the GKE cluster | `string` | `"node-pool-complete-cluster"` | no |
| <a name="input_gke_subnet"></a> [gke\_subnet](#input\_gke\_subnet) | The GKE subnet to use | <pre>object({<br>    name                = string<br>    nodes_cidr_block    = string<br>    pods_cidr_block     = string<br>    services_cidr_block = string<br>    region              = string<br>  })</pre> | <pre>{<br>  "name": "node-pool-complete-subnet",<br>  "nodes_cidr_block": "10.51.0.0/16",<br>  "pods_cidr_block": "192.168.64.0/22",<br>  "region": "europe-west9",<br>  "services_cidr_block": "192.168.1.0/24"<br>}</pre> | no |
| <a name="input_network"></a> [network](#input\_network) | The VPC network name to host the cluster in | `string` | `"node-pool-complete-network"` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region to host the cluster in | `string` | `"europe-west9"` | no |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | value | `string` | `"tf-gke-gke-test-1-k4hk@armonik-gcp-13469.iam.gserviceaccount.com"` | no |

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