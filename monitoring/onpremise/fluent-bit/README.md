<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.21.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_cluster_role.fluent_bit_role](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role.fluent_bit_role_windows](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.fluent_bit_role_binding](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_cluster_role_binding.fluent_bit_role_binding_windows](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_config_map.fluent_bit_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.fluent_bit_config_windows](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.fluent_bit_entrypoint](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.fluent_bit_envvars_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.fluent_bit_envvars_config_windows](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_daemonset.fluent_bit](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/daemonset) | resource |
| [kubernetes_daemonset.fluent_bit_windows](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/daemonset) | resource |
| [kubernetes_secret.aws_auth_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service_account.fluent_bit](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_service_account.fluent_bit_windows](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws"></a> [aws](#input\_aws) | AWS user for logs, prefer to pass them through env('AWS\_*') in your parameters.tfvars | <pre>object({<br>    aws_secret_access_key = optional(string, "")<br>    aws_access_id         = optional(string, "")<br>    aws_session_token     = optional(string, "")<br>  })</pre> | `{}` | no |
| <a name="input_cloudwatch"></a> [cloudwatch](#input\_cloudwatch) | CloudWatch info | `any` | `{}` | no |
| <a name="input_fluent_bit"></a> [fluent\_bit](#input\_fluent\_bit) | Parameters of Fluent bit | <pre>object({<br>    container_name                     = string<br>    image                              = string<br>    tag                                = string<br>    is_daemonset                       = bool<br>    http_server                        = string<br>    http_port                          = string<br>    read_from_head                     = string<br>    read_from_tail                     = string<br>    image_pull_secrets                 = string<br>    parser                             = string<br>    fluent_bit_state_hostpath          = string # path = "/var/log/fluent-bit/state" for GCP Autopilot | path = "/var/fluent-bit/state" for localhost, AWS EKS, GCP GKE<br>    var_lib_docker_containers_hostpath = string # path = "/var/log/lib/docker/containers" for GCP Autopilot | path = "/var/lib/docker/containers" for localhost, AWS EKS, GCP GKE<br>    run_log_journal_hostpath           = string # path = "/var/log/run/log/journal" -for GCP Autopilot | path = "/run/log/journal" for localhost, AWS EKS, GCP GKE<br>  })</pre> | n/a | yes |
| <a name="input_fluent_bit_windows"></a> [fluent\_bit\_windows](#input\_fluent\_bit\_windows) | Parameters of Fluent bit for windows | <pre>object({<br>    container_name                     = optional(string)<br>    image                              = optional(string)<br>    tag                                = optional(string)<br>    is_daemonset                       = optional(bool)<br>    http_server                        = optional(string)<br>    http_port                          = optional(string)<br>    read_from_head                     = optional(string)<br>    read_from_tail                     = optional(string)<br>    image_pull_secrets                 = optional(string)<br>    parser                             = optional(string)<br>    fluent_bit_state_hostpath          = optional(string)<br>    var_lib_docker_containers_hostpath = optional(string)<br>    run_log_journal_hostpath           = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK monitoring | `string` | n/a | yes |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for fluent-bit on linux | `any` | `{}` | no |
| <a name="input_node_selector_windows"></a> [node\_selector\_windows](#input\_node\_selector\_windows) | Node selector for fluent-bit on windows | `any` | `{}` | no |
| <a name="input_s3"></a> [s3](#input\_s3) | S3 for logs | `any` | `{}` | no |
| <a name="input_seq"></a> [seq](#input\_seq) | Seq info | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configmaps"></a> [configmaps](#output\_configmaps) | Configmaps of Fluent-bit |
| <a name="output_container_name"></a> [container\_name](#output\_container\_name) | Container name of Fluent-bit |
| <a name="output_image"></a> [image](#output\_image) | image of Fluent-bit |
| <a name="output_is_daemonset"></a> [is\_daemonset](#output\_is\_daemonset) | Is Fluent-bit a daemonset |
| <a name="output_tag"></a> [tag](#output\_tag) | tag of Fluent-bit |
| <a name="output_windows_configmaps"></a> [windows\_configmaps](#output\_windows\_configmaps) | Configmaps of Fluent-bit |
| <a name="output_windows_container_name"></a> [windows\_container\_name](#output\_windows\_container\_name) | Container name of Fluent-bit |
| <a name="output_windows_image"></a> [windows\_image](#output\_windows\_image) | image of Fluent-bit |
| <a name="output_windows_is_daemonset"></a> [windows\_is\_daemonset](#output\_windows\_is\_daemonset) | Is Fluent-bit a daemonset |
| <a name="output_windows_tag"></a> [windows\_tag](#output\_windows\_tag) | tag of Fluent-bit |
<!-- END_TF_DOCS -->
