# GCP node pool

This module creates GCP node pools, to link to an already existing Kubernetes cluster with Google Kubernetes Engine (GKE). A node pool is a group of virtual machines with the same configuration in a Kubernetes cluster. 
<!-- BEGIN_TF_DOCS -->
Copyright 2022 Google LLC

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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.75.0, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.75.0, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_container_node_pool.pools](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool) | resource |
| [google_container_node_pool.windows_pools](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_base_labels"></a> [base\_labels](#input\_base\_labels) | Map of labels used for all node pools, you can add specific labels to specific node pools in node\_pools variable with the 'labels' key | `map(string)` | `{}` | no |
| <a name="input_base_metadata"></a> [base\_metadata](#input\_base\_metadata) | Map of metadata used for all node pools, you can add specific metadata to specific node pools in node\_pools variable with the 'metadata' key | `map(any)` | `{}` | no |
| <a name="input_base_oauth_scopes"></a> [base\_oauth\_scopes](#input\_base\_oauth\_scopes) | Set of oauth scopes used for all node pools, you can add specific oauth scopes to specific node pools in node\_pools variable with the 'oauth\_scopes' key | `set(string)` | <pre>[<br>  "https://www.googleapis.com/auth/cloud-platform"<br>]</pre> | no |
| <a name="input_base_resource_labels"></a> [base\_resource\_labels](#input\_base\_resource\_labels) | Map of resource labels used for all node pools, you can add specific resource labels to specific node pools in node\_pools variable with the 'resource\_labels' key | `map(string)` | `{}` | no |
| <a name="input_base_tags"></a> [base\_tags](#input\_base\_tags) | Set of tags used for all node pools, you can add specific tags to specific node pools in node\_pools variable with the 'tags' key | `set(string)` | `[]` | no |
| <a name="input_base_taints"></a> [base\_taints](#input\_base\_taints) | Map of taints used for all node pools, you can add specific taints to specific node pools in node\_pools variable with the 'taint' key. Each taint has a value and an effect | <pre>map(object({<br>    value  = bool<br>    effect = string<br>  }))</pre> | `{}` | no |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Cluster location (region or zone) | `string` | `""` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster to create the node pools for | `string` | `""` | no |
| <a name="input_disable_legacy_metadata_endpoints"></a> [disable\_legacy\_metadata\_endpoints](#input\_disable\_legacy\_metadata\_endpoints) | Disable the /0.1/ and /v1beta1/ metadata server endpoints on the node. Changing this value will cause all node pools to be recreated | `bool` | `true` | no |
| <a name="input_min_master_version"></a> [min\_master\_version](#input\_min\_master\_version) | The minimum version of the cluster master | `string` | `null` | no |
| <a name="input_node_metadata"></a> [node\_metadata](#input\_node\_metadata) | Specifies how node metadata is exposed to the workload running on the node. Possible values are GKE\_METADATA, GCE\_METADATA, UNSPECIFIED, GKE\_METADATA\_SERVER or EXPOSE | `string` | `"GKE_METADATA"` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | Map of maps containing the node pools configurations. Multiple keys can be used within a node pool configuration, see : https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool | `any` | `{}` | no |
| <a name="input_release_channel"></a> [release\_channel](#input\_release\_channel) | The release channel of this cluster. Accepted values are `UNSPECIFIED`, `RAPID`, `REGULAR` and `STABLE`. Defaults to `REGULAR` | `string` | `"REGULAR"` | no |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | The service account to run nodes | `string` | `""` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | A map of timeouts for cluster operations | `map(string)` | `{}` | no |
| <a name="input_windows_node_pools"></a> [windows\_node\_pools](#input\_windows\_node\_pools) | Map of maps containing Windows node pools configurations. All keys used for node pool configurations in node\_pools can be used in windows\_node\_pools, see : https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool | `any` | `{}` | no |

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