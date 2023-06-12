<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.21.1 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_config_map.dashboards_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.dashboards_json_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.datasources_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.grafana_ini](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.grafana](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_service.grafana](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [local_file.dashboards_config_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.datasources_config_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_authentication"></a> [authentication](#input\_authentication) | Enables the authentication form | `bool` | `false` | no |
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Docker image for Grafana | <pre>object({<br>    image              = string<br>    tag                = string<br>    image_pull_secrets = string<br>  })</pre> | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK monitoring | `string` | n/a | yes |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for Grafana | `any` | `{}` | no |
| <a name="input_port"></a> [port](#input\_port) | Port for Grafana service | `string` | n/a | yes |
| <a name="input_prometheus_url"></a> [prometheus\_url](#input\_prometheus\_url) | Prometheus URL | `string` | n/a | yes |
| <a name="input_service_type"></a> [service\_type](#input\_service\_type) | Service type which can be: ClusterIP, NodePort or LoadBalancer | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_host"></a> [host](#output\_host) | Host of Grafana |
| <a name="output_port"></a> [port](#output\_port) | Port of Grafana |
| <a name="output_url"></a> [url](#output\_url) | URL of Grafana |
<!-- END_TF_DOCS -->