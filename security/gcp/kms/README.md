# Cloud KMS

Cloud Key Management Service allows you to create, import, and manage cryptographic keys and perform cryptographic
operations in a single centralized cloud service. You can use these keys and perform these operations by using Cloud KMS
directly, by using Cloud HSM or Cloud External Key Manager, or by using Customer-Managed Encryption Keys (CMEK) integrations
within other Google Cloud services.

This module create a key ring with a list of crypto keys with these possibilities :

* Create a KeyRing.
* Configure the IAM policy for the newly created key ring.
* Create a map of crypto keys.
* Configure the IAM policy for the newly created crypto keys.

> Note: KeyRings cannot be deleted from Google Cloud Platform. Destroying a Terraform-managed KeyRing will remove it from state but will not delete the resource from the project. See [Documentation](https://cloud.google.com/kms/docs/destroy-restore#:~:text=Note%3A%20Key%20rings%2C%20keys%2C,unless%20it%20has%20been%20destroyed.).

> Note: CryptoKeys cannot be deleted from Google Cloud Platform. Destroying a Terraform-managed CryptoKey will remove it from state and delete all CryptoKeyVersions, rendering the key unusable, but will not delete the resource from the project. When Terraform destroys these keys, any data previously encrypted with these keys will be irrecoverable. For this reason, it is strongly recommended that you add lifecycle hooks to the resource to prevent accidental destruction.

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
| [google_kms_crypto_key.keys](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key_iam_member.crypto_key_roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_key_ring.key_ring](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) | resource |
| [google_kms_key_ring_iam_member.key_ring_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring_iam_member) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_crypto_keys"></a> [crypto\_keys](#input\_crypto\_keys) | Map of crypto keys representing a logical key that can be used for cryptographic operations. The valid parameters are defined in [Crypto key in Terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key). In addition, a map of roles, of type "map(set(string))", can be defined for each crypto key, ex: "roles = {"roles/cloudkms.cryptoKeyEncrypter" = ["user:jane@example.com", "user:david@example.com"]}". | `any` | `null` | no |
| <a name="input_key_ring_name"></a> [key\_ring\_name](#input\_key\_ring\_name) | The resource name for the KeyRing. | `string` | n/a | yes |
| <a name="input_key_ring_roles"></a> [key\_ring\_roles](#input\_key\_ring\_roles) | Roles to bind to the kKeyRing. | `map(set(string))` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels with user-defined metadata to apply to crypto keys. | `map(string)` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The location for the KeyRing. A full list of valid locations can be found by running "gcloud kms locations list". | `string` | `null` | no |

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
