<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | >= 2.1.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.7.1 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |
| <a name="requirement_pkcs12"></a> [pkcs12](#requirement\_pkcs12) | >= 0.0.7 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_storage"></a> [storage](#input\_storage) | List of needed storage for each data type | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_list_storage"></a> [list\_storage](#output\_list\_storage) | List of deployed storage |
| <a name="output_needed_storage"></a> [needed\_storage](#output\_needed\_storage) | List of storage required by ArmoniK |
<!-- END_TF_DOCS -->