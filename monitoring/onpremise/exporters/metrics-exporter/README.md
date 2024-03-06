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
| <a name="input_metrics_exporter"></a> [metrics\_exporter](#input\_metrics\_exporter) | Metrics\_exporter service parameters | <pre>object({<br>    name          = optional(string, "metrics-exporter")<br>    label_app     = optional(string, "armonik")<br>    label_service = optional(string, "metrics-exporter")<br>    port_name     = optional(string, "metrics")<br>    port          = optional(number, 9419)<br>    target_port   = optional(number, 1080)<br>    protocol      = optional(string, "TCP")<br>  })</pre> | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK resources | `string` | n/a | yes |
| <a name="input_service_type"></a> [service\_type](#input\_service\_type) | Service type which can be: ClusterIP, NodePort or LoadBalancer | `string` | `"ClusterIP"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_host"></a> [host](#output\_host) | Host of Metrics exporter |
| <a name="output_name"></a> [name](#output\_name) | Name of Metrics exporter |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace of Metrics exporter |
| <a name="output_port"></a> [port](#output\_port) | Port of Metrics exporter |
| <a name="output_url"></a> [url](#output\_url) | URL of Metrics exporter |
<!-- END_TF_DOCS -->
