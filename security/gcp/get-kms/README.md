# Cloud KMS

Cloud Key Management Service allows you to create, import, and manage cryptographic keys and perform cryptographic
operations in a single centralized cloud service. You can use these keys and perform these operations by using Cloud KMS
directly, by using Cloud HSM or Cloud External Key Manager, or by using Customer-Managed Encryption Keys (CMEK) integrations
within other Google Cloud services.

This module retrieve a key from the GCP project. 

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.75.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.75.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_kms_crypto_key.my_crypto_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_crypto_key) | data source |
| [google_kms_key_ring.my_key_ring](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_key_ring) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_crypto_key_name"></a> [crypto\_key\_name](#input\_crypto\_key\_name) | The name of the crypto key to retrieve from the GCP project. | `string` | n/a | yes |
| <a name="input_key_ring_name"></a> [key\_ring\_name](#input\_key\_ring\_name) | The key ring name on which the crypto key belongs to. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_my_crypto_key_output"></a> [my\_crypto\_key\_output](#output\_my\_crypto\_key\_output) | The crypto key on the GCP project. |
<!-- END_TF_DOCS -->
