<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_daemonset.node-exporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/daemonset) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Docker image for node exporter | <pre>object({<br>    image              = string<br>    tag                = string<br>    image_pull_secrets = string<br>  })</pre> | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK monitoring | `string` | n/a | yes |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for node exporter | `any` | `{}` | no |
| <a name="input_working_dir"></a> [working\_dir](#input\_working\_dir) | Working directory | `string` | `".."` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->