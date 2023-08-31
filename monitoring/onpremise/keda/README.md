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
| [helm_release.keda](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Docker image for Keda | <pre>object({<br>    keda = object({<br>      image = string<br>      tag   = string<br>    })<br>    metricsApiServer = object({<br>      image = string<br>      tag   = string<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_helm_chart_repository"></a> [helm\_chart\_repository](#input\_helm\_chart\_repository) | Path to helm chart repository for keda | `string` | n/a | yes |
| <a name="input_helm_chart_version"></a> [helm\_chart\_version](#input\_helm\_chart\_version) | Version of chart helm for keda | `string` | n/a | yes |
| <a name="input_imad"></a> [imad](#input\_imad) | Namespace of Keda | `string` | n/a | yes |
| <a name="input_image_pull_secrets"></a> [image\_pull\_secrets](#input\_image\_pull\_secrets) | image\_pull\_secrets for keda | `string` | n/a | yes |
| <a name="input_metrics_server_dns_policy"></a> [metrics\_server\_dns\_policy](#input\_metrics\_server\_dns\_policy) | DNS policy of KEDA operator metrics server | `string` | n/a | yes |
| <a name="input_metrics_server_use_host_network"></a> [metrics\_server\_use\_host\_network](#input\_metrics\_server\_use\_host\_network) | Use or not the host network for KEDA operator metrics server | `bool` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of Keda | `string` | n/a | yes |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for Keda | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_keda"></a> [keda](#output\_keda) | Info about KEDA |
<!-- END_TF_DOCS -->
