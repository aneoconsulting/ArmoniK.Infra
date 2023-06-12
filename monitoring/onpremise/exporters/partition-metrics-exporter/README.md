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
| [kubernetes_config_map.partition_metrics_exporter_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.partition_metrics_exporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_service.partition_metrics_exporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Docker image for partition metrics exporter | <pre>object({<br>    image              = string<br>    tag                = string<br>    image_pull_secrets = string<br>  })</pre> | n/a | yes |
| <a name="input_extra_conf"></a> [extra\_conf](#input\_extra\_conf) | Add extra configuration in the configmaps | `map(string)` | `{}` | no |
| <a name="input_metrics_exporter_url"></a> [metrics\_exporter\_url](#input\_metrics\_exporter\_url) | URL of metrics exporter | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK resources | `string` | n/a | yes |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for partition metrics exporter | `any` | `{}` | no |
| <a name="input_service_type"></a> [service\_type](#input\_service\_type) | Service type which can be: ClusterIP, NodePort or LoadBalancer | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_host"></a> [host](#output\_host) | Host of partition metrics exporter |
| <a name="output_name"></a> [name](#output\_name) | Name of partition metrics exporter |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace of partition metrics exporter |
| <a name="output_port"></a> [port](#output\_port) | Port of partition metrics exporter |
| <a name="output_url"></a> [url](#output\_url) | URL of partition metrics exporter |
<!-- END_TF_DOCS -->