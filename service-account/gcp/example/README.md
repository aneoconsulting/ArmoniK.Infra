<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.75.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.21.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 4.75.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.21.1 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.5.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_complete_vpc"></a> [complete\_vpc](#module\_complete\_vpc) | ../../../networking/gcp/vpc | n/a |
| <a name="module_gke"></a> [gke](#module\_gke) | terraform-google-modules/kubernetes-engine/google | n/a |
| <a name="module_service_account"></a> [service\_account](#module\_service\_account) | ../ | n/a |

## Resources

| Name | Type |
|------|------|
| [kubernetes_pod.test](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/pod) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_image"></a> [image](#input\_image) | Container image for pod | `string` | `"google/cloud-sdk:slim"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"europe-west9"` | no |
| <a name="input_roles"></a> [roles](#input\_roles) | n/a | `list(string)` | <pre>[<br>  "roles/redis.editor",<br>  "roles/pubsub.editor"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_K8s_namespace"></a> [K8s\_namespace](#output\_K8s\_namespace) | Kubernetes service account name |
| <a name="output_gcp_sa_name"></a> [gcp\_sa\_name](#output\_gcp\_sa\_name) | Kubernetes service account name |
| <a name="output_gke_name"></a> [gke\_name](#output\_gke\_name) | Name of VPC |
| <a name="output_k8s_sa_name"></a> [k8s\_sa\_name](#output\_k8s\_sa\_name) | Kubernetes service account name |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | Name of VPC |
<!-- END_TF_DOCS -->