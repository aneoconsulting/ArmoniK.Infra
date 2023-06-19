<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.10.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.10.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.metrics_server](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_args"></a> [default\_args](#input\_default\_args) | Default args for metrics server | `list(string)` | n/a | yes |
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Docker image for metrics server | <pre>object({<br>    image = string<br>    tag   = string<br>  })</pre> | n/a | yes |
| <a name="input_helm_chart_repository"></a> [helm\_chart\_repository](#input\_helm\_chart\_repository) | Path to helm chart repository for metrics server | `string` | n/a | yes |
| <a name="input_helm_chart_version"></a> [helm\_chart\_version](#input\_helm\_chart\_version) | Version of chart helm for metrics server | `string` | n/a | yes |
| <a name="input_host_network"></a> [host\_network](#input\_host\_network) | Host network for metrics server | `bool` | n/a | yes |
| <a name="input_image_pull_secrets"></a> [image\_pull\_secrets](#input\_image\_pull\_secrets) | image\_pull\_secrets for metrics server | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of metrics server | `string` | n/a | yes |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for metrics server | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_metrics_server"></a> [metrics\_server](#output\_metrics\_server) | Info about Metrics server |
<!-- END_TF_DOCS -->
