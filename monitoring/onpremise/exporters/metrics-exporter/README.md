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
| [kubernetes_service.metrics_exporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_label_app"></a> [label\_app](#input\_label\_app) | Service label app | `string` | `"armonik"` | no |
| <a name="input_label_service"></a> [label\_service](#input\_label\_service) | Service label service type | `string` | `"metrics-exporter"` | no |
| <a name="input_name"></a> [name](#input\_name) | Service name | `string` | `"metrics-exporter"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK resources | `string` | n/a | yes |
| <a name="input_port"></a> [port](#input\_port) | Service port | `number` | `9419` | no |
| <a name="input_port_name"></a> [port\_name](#input\_port\_name) | Service port name | `string` | `"metrics"` | no |
| <a name="input_service_type"></a> [service\_type](#input\_service\_type) | Service type which can be: ClusterIP, NodePort or LoadBalancer | `string` | `"ClusterIP"` | no |
| <a name="input_target_port"></a> [target\_port](#input\_target\_port) | Service target port | `number` | `1080` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_host"></a> [host](#output\_host) | Host of Metrics exporter |
| <a name="output_name"></a> [name](#output\_name) | Name of Metrics exporter |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace of Metrics exporter |
| <a name="output_port"></a> [port](#output\_port) | Port of Metrics exporter |
| <a name="output_url"></a> [url](#output\_url) | URL of Metrics exporter |
<!-- END_TF_DOCS -->
