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
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Id of the crypto KMS used to encrypt/decrypt resources | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix of the topic and subscription name | `string` | `""` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Id of the google project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_env"></a> [env](#output\_env) | Elements to be set as environment variables |
<!-- END_TF_DOCS -->