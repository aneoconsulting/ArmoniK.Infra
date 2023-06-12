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
| [kubernetes_cron_job_v1.retention_job_in_seq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cron_job_v1) | resource |
| [kubernetes_deployment.seq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_service.seq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service.seq_web_console](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_authentication"></a> [authentication](#input\_authentication) | Enables the authentication form | `bool` | `false` | no |
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Docker image for Seq | <pre>object({<br>    image              = string<br>    tag                = string<br>    image_pull_secrets = string<br>  })</pre> | n/a | yes |
| <a name="input_docker_image_cron"></a> [docker\_image\_cron](#input\_docker\_image\_cron) | Docker image cron for Seq | <pre>object({<br>    image              = string<br>    tag                = string<br>    image_pull_secrets = string<br>  })</pre> | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK monitoring | `string` | n/a | yes |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for Seq | `any` | `{}` | no |
| <a name="input_port"></a> [port](#input\_port) | Port for Seq service | `string` | n/a | yes |
| <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days) | Retention of Seq logs in days | `string` | n/a | yes |
| <a name="input_service_type"></a> [service\_type](#input\_service\_type) | Service type which can be: ClusterIP, NodePort or LoadBalancer | `string` | n/a | yes |
| <a name="input_system_ram_target"></a> [system\_ram\_target](#input\_system\_ram\_target) | Target RAM size | `number` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_host"></a> [host](#output\_host) | Host of Seq |
| <a name="output_port"></a> [port](#output\_port) | Port of Seq |
| <a name="output_url"></a> [url](#output\_url) | URL of Seq |
| <a name="output_web_url"></a> [web\_url](#output\_web\_url) | Web URL of Seq |
<!-- END_TF_DOCS -->