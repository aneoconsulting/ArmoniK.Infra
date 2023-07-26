<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.38.0, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.38.0, < 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_storage_bucket.bucket_creation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_acl.bucket_acls_creation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_acl) | resource |
| [google_storage_bucket_iam_binding.bucket_policy_creation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_binding) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autoclass"></a> [autoclass](#input\_autoclass) | The bucket's Autoclass configuration. | <pre>object({<br>    enabled = bool<br>  })</pre> | `null` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | The name of the bucket. | `string` | n/a | yes |
| <a name="input_cors"></a> [cors](#input\_cors) | The bucket's Cross-Origin Resource Sharing (CORS) configuration. | <pre>object({<br>    origin          = optional(list(string))<br>    method          = optional(list(string))<br>    response_header = optional(list(string))<br>    max_age_seconds = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_credentials_file"></a> [credentials\_file](#input\_credentials\_file) | The credential json file | `string` | n/a | yes |
| <a name="input_custom_placement_config"></a> [custom\_placement\_config](#input\_custom\_placement\_config) | The bucket's custom location configuration, which specifies the individual regions that comprise a dual-region bucket. If the bucket is designated a single or multi-region, the parameters are empty. | <pre>object({<br>    data_locations = list(string)<br>  })</pre> | `null` | no |
| <a name="input_default_event_based_hold"></a> [default\_event\_based\_hold](#input\_default\_event\_based\_hold) | Whether or not to automatically apply an eventBasedHold to new objects added to the bucket. | `bool` | `false` | no |
| <a name="input_encryption"></a> [encryption](#input\_encryption) | The bucket's encryption configuration. | <pre>object({<br>    default_kms_key_name = string<br>  })</pre> | `null` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | When deleting a bucket, this boolean option will delete all contained objects. | `bool` | `false` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A map of key/value label pairs to assign to the bucket. | `map(string)` | `{}` | no |
| <a name="input_lifecycle_rule"></a> [lifecycle\_rule](#input\_lifecycle\_rule) | The bucket's Lifecycle Rules configuration. | <pre>object({<br>    action        = object({<br>      type          = string<br>      storage_class = string<br>    })<br>    condition = object ({<br>      age                        = optional(number)<br>      created_before             = optional(string)<br>      with_state                 = optional(string)<br>      matches_storage_class      = optional(list(string))<br>      matches_prefix             = optional(list(string))<br>      matches_suffix             = optional(list(string))<br>      num_newer_versions         = optional(number)<br>      custom_time_before         = optional(string)<br>      days_since_custom_time     = optional(string)<br>      days_since_noncurrent_time = optional(string)<br>      noncurrent_time_before     = optional(string)<br>    })<br>  })</pre> | `null` | no |
| <a name="input_logging"></a> [logging](#input\_logging) | The bucket's Access & Storage Logs configuration. | <pre>object({<br>    log_bucket        = string<br>    log_object_prefix = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_policy_data"></a> [policy\_data](#input\_policy\_data) | Policy data to bind to the bucket | `map(list(string))` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The id project where to create the bucket | `string` | n/a | yes |
| <a name="input_public_access_prevention"></a> [public\_access\_prevention](#input\_public\_access\_prevention) | Prevents public access to a bucket. Acceptable values are 'inherited' or 'enforced' | `string` | `"inherited"` | no |
| <a name="input_region"></a> [region](#input\_region) | the region where to create the bucket | `string` | n/a | yes |
| <a name="input_requester_pays"></a> [requester\_pays](#input\_requester\_pays) | Enables Requester Pays on a storage bucket. | `bool` | `false` | no |
| <a name="input_retention_policy"></a> [retention\_policy](#input\_retention\_policy) | Configuration of the bucket's data retention policy for how long objects in the bucket should be retained. | <pre>object({<br>    is_locked        = optional(bool)<br>    retention_period = number<br>  })</pre> | `null` | no |
| <a name="input_role_entity"></a> [role\_entity](#input\_role\_entity) | List of role/entity pairs for acls bucket | `list(string)` | `[]` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | The Storage Class of the new bucket. Supported values include: STANDARD (default), MULTI\_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE. | `string` | `"STANDARD"` | no |
| <a name="input_uniform_bucket_level_access"></a> [uniform\_bucket\_level\_access](#input\_uniform\_bucket\_level\_access) | Enables Uniform bucket-level access access to a bucket | `bool` | `false` | no |
| <a name="input_versioning"></a> [versioning](#input\_versioning) | The bucket's Versioning configuration. | <pre>object({<br>    enabled = bool<br>  })</pre> | `null` | no |
| <a name="input_website"></a> [website](#input\_website) | Configuration if the bucket acts as a website. Structure is documented below. | <pre>object({<br>    main_page_suffix = optional(string)<br>    not_found_page   = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | The zone where to create the bucket | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acls_bucket"></a> [acls\_bucket](#output\_acls\_bucket) | The associated ACLS |
| <a name="output_bucket"></a> [bucket](#output\_bucket) | bucket created on GCP |
| <a name="output_iam_bucket"></a> [iam\_bucket](#output\_iam\_bucket) | The associated IAM policy |
<!-- END_TF_DOCS -->