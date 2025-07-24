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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mongodb_aggregator"></a> [mongodb\_aggregator](#module\_mongodb\_aggregator) | ../../../../utils/aggregator | n/a |

## Resources

| Name | Type |
|------|------|
| [kubernetes_deployment.mongodb_exporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_service.mongodb_exporter_service](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_disable_diagnostic_data"></a> [disable\_diagnostic\_data](#input\_disable\_diagnostic\_data) | When working with a sharded on-premise MongoDB deployment, this flag works around the exporter crashing (but exports less metrics) | `bool` | `false` | no |
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Docker image for MongoDB metrics exporter | <pre>object({<br/>    image              = string<br/>    tag                = string<br/>    image_pull_secrets = string<br/>  })</pre> | n/a | yes |
| <a name="input_force_split_cluster"></a> [force\_split\_cluster](#input\_force\_split\_cluster) | Used when working with mongodb+srv URIs (this is typically the case with Atlas-managed MongoDB), it adds the '--split-cluster' flag to the exporter flags. You can force this to be on. | `bool` | `false` | no |
| <a name="input_mongodb_modules"></a> [mongodb\_modules](#input\_mongodb\_modules) | MongoDB modules to use when building the exporter (assumes only one is actually active) | `any` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace to use for this resource | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace of the MongoDB metrics exporter |
| <a name="output_url"></a> [url](#output\_url) | Url of the MongoDB Metrics exporter |
<!-- END_TF_DOCS -->