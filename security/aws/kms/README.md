# AWS KMS
AWS Key Management Service (AWS KMS) lets you create, manage, and control cryptographic keys across your applications and AWS services. 
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.61 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.61 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.kms_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bypass_policy_lockout_safety_check"></a> [bypass\_policy\_lockout\_safety\_check](#input\_bypass\_policy\_lockout\_safety\_check) | A flag to indicate whether to bypass the key policy lockout safety check. Setting this value to true increases the risk that the KMS key becomes unmanageable | `bool` | `null` | no |
| <a name="input_create"></a> [create](#input\_create) | Determines whether resources will be created (affects all resources) | `bool` | `true` | no |
| <a name="input_customer_master_key_spec"></a> [customer\_master\_key\_spec](#input\_customer\_master\_key\_spec) | Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports. Valid values: `SYMMETRIC_DEFAULT`, `RSA_2048`, `RSA_3072`, `RSA_4096`, `HMAC_256`, `ECC_NIST_P256`, `ECC_NIST_P384`, `ECC_NIST_P521`, or `ECC_SECG_P256K1`. Defaults to `SYMMETRIC_DEFAULT` | `string` | `"SYMMETRIC_DEFAULT"` | no |
| <a name="input_deletion_window_in_days"></a> [deletion\_window\_in\_days](#input\_deletion\_window\_in\_days) | The waiting period, specified in number of days. After the waiting period ends, AWS KMS deletes the KMS key. If you specify a value, it must be between `7` and `30`, inclusive. If you do not specify a value, it defaults to `30` | `number` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | The description of the key as viewed in AWS console | `string` | `null` | no |
| <a name="input_enable_default_policy"></a> [enable\_default\_policy](#input\_enable\_default\_policy) | Specifies whether to enable the default key policy. Defaults to `true` | `bool` | `true` | no |
| <a name="input_enable_key_rotation"></a> [enable\_key\_rotation](#input\_enable\_key\_rotation) | Specifies whether key rotation is enabled. Defaults to `true` | `bool` | `true` | no |
| <a name="input_enable_route53_dnssec"></a> [enable\_route53\_dnssec](#input\_enable\_route53\_dnssec) | Determines whether the KMS policy used for Route53 DNSSEC signing is enabled | `bool` | `false` | no |
| <a name="input_is_enabled"></a> [is\_enabled](#input\_is\_enabled) | Specifies whether the key is enabled. Defaults to `true` | `bool` | `null` | no |
| <a name="input_key_administrators"></a> [key\_administrators](#input\_key\_administrators) | A list of IAM ARNs for [key administrators](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators) | `list(string)` | `[]` | no |
| <a name="input_key_asymmetric_public_encryption_users"></a> [key\_asymmetric\_public\_encryption\_users](#input\_key\_asymmetric\_public\_encryption\_users) | A list of IAM ARNs for [key asymmetric public encryption users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-users-crypto) | `list(string)` | `[]` | no |
| <a name="input_key_asymmetric_sign_verify_users"></a> [key\_asymmetric\_sign\_verify\_users](#input\_key\_asymmetric\_sign\_verify\_users) | A list of IAM ARNs for [key asymmetric sign and verify users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-users-crypto) | `list(string)` | `[]` | no |
| <a name="input_key_hmac_users"></a> [key\_hmac\_users](#input\_key\_hmac\_users) | A list of IAM ARNs for [key HMAC users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-users-crypto) | `list(string)` | `[]` | no |
| <a name="input_key_owners"></a> [key\_owners](#input\_key\_owners) | A list of IAM ARNs for those who will have full key permissions (`kms:*`) | `list(string)` | `[]` | no |
| <a name="input_key_service_roles_for_autoscaling"></a> [key\_service\_roles\_for\_autoscaling](#input\_key\_service\_roles\_for\_autoscaling) | A list of IAM ARNs for [AWSServiceRoleForAutoScaling roles](https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html#policy-example-cmk-access) | `list(string)` | `[]` | no |
| <a name="input_key_service_users"></a> [key\_service\_users](#input\_key\_service\_users) | A list of IAM ARNs for [key service users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-service-integration) | `list(string)` | `[]` | no |
| <a name="input_key_statements"></a> [key\_statements](#input\_key\_statements) | A map of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) for custom permission usage | `any` | `{}` | no |
| <a name="input_key_symmetric_encryption_users"></a> [key\_symmetric\_encryption\_users](#input\_key\_symmetric\_encryption\_users) | A list of IAM ARNs for [key symmetric encryption users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-users-crypto) | `list(string)` | `[]` | no |
| <a name="input_key_usage"></a> [key\_usage](#input\_key\_usage) | Specifies the intended use of the key. Valid values: `ENCRYPT_DECRYPT` or `SIGN_VERIFY`. Defaults to `ENCRYPT_DECRYPT` | `string` | `null` | no |
| <a name="input_key_users"></a> [key\_users](#input\_key\_users) | A list of IAM ARNs for [key users](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-users) | `list(string)` | `[]` | no |
| <a name="input_multi_region"></a> [multi\_region](#input\_multi\_region) | Indicates whether the KMS key is a multi-Region (`true`) or regional (`false`) key. Defaults to `false` | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | AWS Key Management Service parameters | `string` | `"armonik-kms"` | no |
| <a name="input_override_policy_documents"></a> [override\_policy\_documents](#input\_override\_policy\_documents) | List of IAM policy documents that are merged together into the exported document. In merging, statements with non-blank `sid`s will override statements with the same `sid` | `list(string)` | `[]` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | A valid policy JSON document. Although this is a key policy, not an IAM policy, an `aws_iam_policy_document`, in the form that designates a principal, can be used | `string` | `null` | no |
| <a name="input_route53_dnssec_sources"></a> [route53\_dnssec\_sources](#input\_route53\_dnssec\_sources) | A list of maps containing `account_ids` and Route53 `hosted_zone_arn` that will be allowed to sign DNSSEC records | `list(any)` | `[]` | no |
| <a name="input_source_policy_documents"></a> [source\_policy\_documents](#input\_source\_policy\_documents) | List of IAM policy documents that are merged together into the exported document. Statements must have unique `sid`s | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_key_arn"></a> [key\_arn](#output\_key\_arn) | The Amazon Resource Name (ARN) of the key |
| <a name="output_key_id"></a> [key\_id](#output\_key\_id) | The globally unique identifier for the key |
| <a name="output_kms_alias"></a> [kms\_alias](#output\_kms\_alias) | Alias KMS |
<!-- END_TF_DOCS -->
