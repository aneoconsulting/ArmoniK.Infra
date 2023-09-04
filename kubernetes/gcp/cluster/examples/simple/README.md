# Simple Gke exemple
This example illustrates how to create a simple GKE cluster.
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gke"></a> [gke](#module\_gke) | ../../../../gcp/cluster | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../../../../networking/gcp/vpc | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name for the GKE cluster | `string` | `"gke-complete-cluster"` | no |
| <a name="input_gke_subnet"></a> [gke\_subnet](#input\_gke\_subnet) | Map of GKE subnets | <pre>object({<br>    name                = string<br>    nodes_cidr_block    = string<br>    pods_cidr_block     = string<br>    services_cidr_block = string<br>    region              = string<br>  })</pre> | <pre>{<br>  "name": "gke-complete-subnet",<br>  "nodes_cidr_block": "10.51.0.0/16",<br>  "pods_cidr_block": "192.168.64.0/22",<br>  "region": "europe-west9",<br>  "services_cidr_block": "192.168.1.0/24"<br>}</pre> | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | value | `string` | `null` | no |
| <a name="input_network"></a> [network](#input\_network) | The VPC network created to host the cluster in | `string` | `"gke-complet-network"` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region to host the cluster in | `string` | `"europe-west9"` | no |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | value | `string` | `"tf-gke-gke-test-1-k4hk@armonik-gcp-13469.iam.gserviceaccount.com"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ca_certificate"></a> [ca\_certificate](#output\_ca\_certificate) | Cluster ca certificate (base64 encoded) |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Cluster ID |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Cluster endpoint |
| <a name="output_kubeconfig_path"></a> [kubeconfig\_path](#output\_kubeconfig\_path) | value |
| <a name="output_location"></a> [location](#output\_location) | Cluster location (region if regional cluster, zone if zonal cluster) |
| <a name="output_name"></a> [name](#output\_name) | Cluster name |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | The service account to default running nodes as if not overridden in `node_pools`. |
<!-- END_TF_DOCS -->