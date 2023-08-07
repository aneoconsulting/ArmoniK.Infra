Cloud Key Management Service allows you to create, import, and manage cryptographic keys and perform cryptographic operations in a single centralized cloud service. You can use these keys and perform these operations by using Cloud KMS directly, by using Cloud HSM or Cloud External Key Manager, or by using Customer-Managed Encryption Keys (CMEK) integrations within other Google Cloud services.

This module create a crypto key and a key ring with these possibilities :

Configure the IAM policy for the newly created crypto key.
Configure the IAM policy for the newly created key ring.
Create a KMS key import job.
Create a ciphertext encryption on a key.
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
| [google_kms_crypto_key.kms_crypto_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key_iam_member.crypto_key_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_key_ring.key_ring](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) | resource |
| [google_kms_key_ring_iam_member.key_ring_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring_iam_member) | resource |
| [google_kms_key_ring_import_job.kms_key_ring_import_job](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring_import_job) | resource |
| [google_kms_secret_ciphertext.ciphertext_password](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_secret_ciphertext) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_crypto_key_roles"></a> [crypto\_key\_roles](#input\_crypto\_key\_roles) | Roles to bind to the crypto key | `map(set(string))` | `null` | no |
| <a name="input_google_kms_key_ring_import_job_id"></a> [google\_kms\_key\_ring\_import\_job\_id](#input\_google\_kms\_key\_ring\_import\_job\_id) | It must be unique within a KeyRing. If not specified it will not create an import job. | `string` | `null` | no |
| <a name="input_google_kms_key_ring_import_job_method"></a> [google\_kms\_key\_ring\_import\_job\_method](#input\_google\_kms\_key\_ring\_import\_job\_method) | The wrapping method to be used for incoming key material. | `string` | `"RSA_OAEP_3072_SHA1_AES_256"` | no |
| <a name="input_google_kms_key_ring_import_job_protection_level"></a> [google\_kms\_key\_ring\_import\_job\_protection\_level](#input\_google\_kms\_key\_ring\_import\_job\_protection\_level) | The protection level of the ImportJob. | `string` | `"SOFTWARE"` | no |
| <a name="input_google_kms_secret_ciphertext_additional_authenticated_data"></a> [google\_kms\_secret\_ciphertext\_additional\_authenticated\_data](#input\_google\_kms\_secret\_ciphertext\_additional\_authenticated\_data) | The additional authenticated data used for integrity checks during encryption and decryption. | `string` | `null` | no |
| <a name="input_google_kms_secret_ciphertext_plaintext"></a> [google\_kms\_secret\_ciphertext\_plaintext](#input\_google\_kms\_secret\_ciphertext\_plaintext) | The plaintext to be encrypted. If not specified it will not create the KMS Ciphertext | `string` | `null` | no |
| <a name="input_key_ring_roles"></a> [key\_ring\_roles](#input\_key\_ring\_roles) | Roles to bind to the key ring | `map(set(string))` | `null` | no |
| <a name="input_kms_crypto_key_import_only"></a> [kms\_crypto\_key\_import\_only](#input\_kms\_crypto\_key\_import\_only) | Whether this key may contain imported versions only. | `bool` | `false` | no |
| <a name="input_kms_crypto_key_labels"></a> [kms\_crypto\_key\_labels](#input\_kms\_crypto\_key\_labels) | Labels with user-defined metadata to apply to this resource. | `map(string)` | `null` | no |
| <a name="input_kms_crypto_key_name"></a> [kms\_crypto\_key\_name](#input\_kms\_crypto\_key\_name) | The resource name for the CryptoKey. | `string` | n/a | yes |
| <a name="input_kms_crypto_key_purpose"></a> [kms\_crypto\_key\_purpose](#input\_kms\_crypto\_key\_purpose) | The immutable purpose of this CryptoKey. | `string` | `"ENCRYPT_DECRYPT"` | no |
| <a name="input_kms_crypto_key_rotation_period"></a> [kms\_crypto\_key\_rotation\_period](#input\_kms\_crypto\_key\_rotation\_period) | Every time this period passes, generate a new CryptoKeyVersion and set it as the primary. The first rotation will take place after the specified period. | `number` | `null` | no |
| <a name="input_kms_crypto_key_skip_initial_version_creation"></a> [kms\_crypto\_key\_skip\_initial\_version\_creation](#input\_kms\_crypto\_key\_skip\_initial\_version\_creation) | If set to true, the request will create a CryptoKey without any CryptoKeyVersions. | `bool` | `false` | no |
| <a name="input_kms_crypto_key_version_template"></a> [kms\_crypto\_key\_version\_template](#input\_kms\_crypto\_key\_version\_template) | A template describing settings for new crypto key versions. | <pre>object({<br>    algorithm        = string<br>    protection_level = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_kms_key_ring_name"></a> [kms\_key\_ring\_name](#input\_kms\_key\_ring\_name) | The resource name for the KeyRing. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_crypto_key"></a> [crypto\_key](#output\_crypto\_key) | The generated crytpo key. |
| <a name="output_kms_ciphertext"></a> [kms\_ciphertext](#output\_kms\_ciphertext) | The ciphertext used to encrypt secret data. |
| <a name="output_kms_crypto_roles"></a> [kms\_crypto\_roles](#output\_kms\_crypto\_roles) | The associated roles on the crytpo key. |
| <a name="output_kms_key_ring"></a> [kms\_key\_ring](#output\_kms\_key\_ring) | The generated key ring. |
| <a name="output_kms_key_ring_import_job"></a> [kms\_key\_ring\_import\_job](#output\_kms\_key\_ring\_import\_job) | The import generated import job. |
| <a name="output_kms_ring_roles"></a> [kms\_ring\_roles](#output\_kms\_ring\_roles) | The associated roles on the key ring. |
<!-- END_TF_DOCS -->