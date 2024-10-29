<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.21.1 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.4.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_cluster_role.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_cluster_role_binding.prometheus_ns_armonik](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_config_map.prometheus_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_persistent_volume_claim.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_service.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_storage_class.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [local_file.prometheus_config_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_string.random_resources](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Docker image for Prometheus | <pre>object({<br>    image              = string<br>    tag                = string<br>    image_pull_secrets = string<br>  })</pre> | n/a | yes |
| <a name="input_metrics_exporter_url"></a> [metrics\_exporter\_url](#input\_metrics\_exporter\_url) | URL of metrics exporter | `string` | n/a | yes |
| <a name="input_mongo_metrics_exporter_url"></a> [mongo\_metrics\_exporter\_url](#input\_mongo\_metrics\_exporter\_url) | URL of the MongoDB metrics exporter | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK monitoring | `string` | n/a | yes |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for Prometheus | `any` | `{}` | no |
| <a name="input_persistent_volume"></a> [persistent\_volume](#input\_persistent\_volume) | Persistent volume info | <pre>object({<br>    storage_provisioner = string<br>    volume_binding_mode = string<br>    parameters          = map(string)<br>    # Resources for PVC<br>    resources = object({<br>      limits = object({<br>        storage = string<br>      })<br>      requests = object({<br>        storage = string<br>      })<br>    })<br>  })</pre> | `null` | no |
| <a name="input_security_context"></a> [security\_context](#input\_security\_context) | security context for Prometheus pods | <pre>object({<br>    run_as_user = number<br>    fs_group    = number<br>  })</pre> | <pre>{<br>  "fs_group": 65534,<br>  "run_as_user": 65534<br>}</pre> | no |
| <a name="input_service_type"></a> [service\_type](#input\_service\_type) | Service type which can be: ClusterIP, NodePort or LoadBalancer | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_host"></a> [host](#output\_host) | Host of prometheus |
| <a name="output_port"></a> [port](#output\_port) | Port of prometheus |
| <a name="output_url"></a> [url](#output\_url) | URL of prometheus |
<!-- END_TF_DOCS -->
