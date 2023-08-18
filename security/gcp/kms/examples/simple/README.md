# GCP Cloud KMS

To create a simple GCP Cloud KMS:

```bash
terraform init
terraform plan
terraform apply
```

To delete all resource:

```bash
terraform destroy
`

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.75.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_simple_kms"></a> [simple\_kms](#module\_simple\_kms) | ../../../kms | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | The GCP region used to deploy the KMS. | `string` | `"europe-west9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_crypto_key_ids"></a> [crypto\_key\_ids](#output\_crypto\_key\_ids) | The Map of the created crypto keys. |
| <a name="output_key_ring_id"></a> [key\_ring\_id](#output\_key\_ring\_id) | The ID of the KeyRing. |
| <a name="output_key_ring_location"></a> [key\_ring\_location](#output\_key\_ring\_location) | The location for the KeyRing. |
| <a name="output_key_ring_name"></a> [key\_ring\_name](#output\_key\_ring\_name) | The resource name for the KeyRing. |
<!-- END_TF_DOCS -->