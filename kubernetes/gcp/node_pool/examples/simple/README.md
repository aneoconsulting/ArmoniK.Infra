# Complete node pools

This example illustrates how to create a simple GKE node pools and outputs a `kubeconfig`

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_name\_suffix | A suffix to append to the default cluster name | `string` | `""` | no |
| compute\_engine\_service\_account | Service account to associate to the nodes in the cluster | `any` | n/a | yes |
| ip\_range\_pods | The secondary ip range to use for pods | `any` | n/a | yes |
| ip\_range\_services | The secondary ip range to use for services | `any` | n/a | yes |
| network | The VPC network to host the cluster in | `any` | n/a | yes |
| project\_id | The project ID to host the cluster in | `any` | n/a | yes |
| region | The region to host the cluster in | `any` | n/a | yes |
| subnetwork | The subnetwork to host the cluster in | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| ca\_certificate | n/a |
| client\_token | n/a |
| cluster\_name | Cluster name |
| ip\_range\_pods | The secondary IP range used for pods |
| ip\_range\_services | The secondary IP range used for services |
| kubeconfig\_raw | n/a |
| kubernetes\_endpoint | n/a |
| location | n/a |
| master\_kubernetes\_version | The master Kubernetes version |
| network | n/a |
| project\_id | n/a |
| region | n/a |
| service\_account | The default service account used for running nodes. |
| subnetwork | n/a |
| zones | List of zones in which the cluster resides |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

To provision this example, run the following from within this directory:
- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
- `terraform destroy` to destroy the built infrastructure

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
| <a name="module_node_pool"></a> [node\_pool](#module\_node\_pool) | ../../../node_pool | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../../../../networking/gcp/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/2.4.0/docs/resources/file) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name for the GKE cluster | `string` | `"node-pool-simple-cluster"` | no |
| <a name="input_gke_subnet"></a> [gke\_subnet](#input\_gke\_subnet) | The GKE subnet to use | <pre>object({<br>    name                = string<br>    nodes_cidr_block    = string<br>    pods_cidr_block     = string<br>    services_cidr_block = string<br>    region              = string<br>  })</pre> | <pre>{<br>  "name": "node-pool-simple-subnet",<br>  "nodes_cidr_block": "10.51.0.0/16",<br>  "pods_cidr_block": "192.168.64.0/22",<br>  "region": "europe-west9",<br>  "services_cidr_block": "192.168.1.0/24"<br>}</pre> | no |
| <a name="input_network"></a> [network](#input\_network) | The VPC network name to host the cluster in | `string` | `"node-pool-simple-network"` | no |
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