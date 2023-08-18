# GCP Cloud KMS

To create a complete GCP Cloud KMS:

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

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | n/a |
| <a name="provider_google"></a> [google](#provider\_google) | ~> 4.75.0 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_complete_kms"></a> [complete\_kms](#module\_complete\_kms) | ../../../kms | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.date_sh](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.timestamp](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [external_external.static_timestamp](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [google_client_openid_userinfo.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_openid_userinfo) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | The GCP region used to deploy the KMS. | `string` | `"europe-west9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_crypto_key_ids"></a> [crypto\_key\_ids](#output\_crypto\_key\_ids) | The Map of the created crypto keys. |
| <a name="output_crypto_key_roles"></a> [crypto\_key\_roles](#output\_crypto\_key\_roles) | The IAM roles for the crypto keys. |
| <a name="output_key_ring_id"></a> [key\_ring\_id](#output\_key\_ring\_id) | The ID of the KeyRing. |
| <a name="output_key_ring_location"></a> [key\_ring\_location](#output\_key\_ring\_location) | The location for the KeyRing. |
| <a name="output_key_ring_name"></a> [key\_ring\_name](#output\_key\_ring\_name) | The resource name for the KeyRing. |
| <a name="output_key_ring_roles"></a> [key\_ring\_roles](#output\_key\_ring\_roles) | The IAM roles for the KeyRing. |
<!-- END_TF_DOCS -->