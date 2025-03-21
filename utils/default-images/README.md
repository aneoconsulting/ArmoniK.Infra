<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_armonik_images"></a> [armonik\_images](#input\_armonik\_images) | Image names of all the ArmoniK components | <pre>object({<br/>    infra         = set(string)<br/>    infra_plugins = set(string)<br/>    core          = set(string)<br/>    api           = set(string)<br/>    gui           = set(string)<br/>    extcsharp     = set(string)<br/>    samples       = set(string)<br/>  })</pre> | n/a | yes |
| <a name="input_armonik_versions"></a> [armonik\_versions](#input\_armonik\_versions) | Versions of all the ArmoniK components | <pre>object({<br/>    infra         = string<br/>    infra_plugins = string<br/>    core          = string<br/>    api           = string<br/>    gui           = string<br/>    extcsharp     = string<br/>    samples       = string<br/>  })</pre> | n/a | yes |
| <a name="input_image_tags"></a> [image\_tags](#input\_image\_tags) | Tags of images used | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_armonik_versions"></a> [armonik\_versions](#output\_armonik\_versions) | Versions of all the ArmoniK components |
| <a name="output_image_tags"></a> [image\_tags](#output\_image\_tags) | Tags of images used |
<!-- END_TF_DOCS -->
