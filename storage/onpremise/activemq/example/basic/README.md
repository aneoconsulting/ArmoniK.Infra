<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.21.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.21.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_activemq"></a> [activemq](#module\_activemq) | ../../../activemq | n/a |

## Resources

| Name | Type |
|------|------|
| [kubernetes_namespace.armonik](https://registry.terraform.io/providers/hashicorp/kubernetes/2.21.1/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_image"></a> [image](#input\_image) | images of services | `string` | `"symptoma/activemq"` | no |
| <a name="input_image_pull_secrets"></a> [image\_pull\_secrets](#input\_image\_pull\_secrets) | (Optional) Specify list of pull secrets | `map(string)` | `{}` | no |
| <a name="input_kub_config_context"></a> [kub\_config\_context](#input\_kub\_config\_context) | value | `string` | n/a | yes |
| <a name="input_kub_config_path"></a> [kub\_config\_path](#input\_kub\_config\_path) | value | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | value | `string` | `"activemq"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK storage resources | `string` | n/a | yes |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Specify node selector for pod | `map(string)` | `{}` | no |
| <a name="input_tag"></a> [tag](#input\_tag) | tag of images | `string` | `"5.17.0"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->