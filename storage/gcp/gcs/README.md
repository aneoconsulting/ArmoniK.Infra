# Google Cloud Storage

Google Cloud Storage allows world-wide storage and retrieval of any amount of data at any time. You can use Cloud Storage
for a range of scenarios including serving website content, storing data for archival and disaster recovery, or distributing
large data objects to users via direct download.

This module creates a Google Cloud Storage with these possibilities :

* Add ACLs on the newly created cloud storage.
* Bind IAM Roles to the newly created cloud storage.

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
| [google_storage_bucket.gcs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_access_control.access_control](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_access_control) | resource |
| [google_storage_bucket_acl.default_acl](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_acl) | resource |
| [google_storage_bucket_acl.predefined_acl](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_acl) | resource |
| [google_storage_bucket_acl.role_entity_acl](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_acl) | resource |
| [google_storage_bucket_iam_member.role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autoclass"></a> [autoclass](#input\_autoclass) | The bucket's Autoclass configuration. | `bool` | `null` | no |
| <a name="input_cors"></a> [cors](#input\_cors) | The bucket's Cross-Origin Resource Sharing (CORS) configuration. | <pre>object({<br>    origin          = list(string)<br>    method          = list(string)<br>    response_header = list(string)<br>    max_age_seconds = number<br>  })</pre> | `null` | no |
| <a name="input_data_locations"></a> [data\_locations](#input\_data\_locations) | The bucket's custom location configuration, which specifies the individual regions that comprise a dual-region bucket. If the bucket is designated a single or multi-region, the parameters are empty. | `list(string)` | `null` | no |
| <a name="input_default_acl"></a> [default\_acl](#input\_default\_acl) | Configure this ACL to be the default ACL. | `string` | `null` | no |
| <a name="input_default_event_based_hold"></a> [default\_event\_based\_hold](#input\_default\_event\_based\_hold) | Whether or not to automatically apply an eventBasedHold to new objects added to the bucket. | `bool` | `null` | no |
| <a name="input_default_kms_key_name"></a> [default\_kms\_key\_name](#input\_default\_kms\_key\_name) | The id of a Cloud KMS key that will be used to encrypt objects inserted into this bucket, if no encryption method is specified. | `string` | `null` | no |
| <a name="input_entity_bucket_access_control"></a> [entity\_bucket\_access\_control](#input\_entity\_bucket\_access\_control) | he entity holding the permission. | `string` | `null` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | When deleting a bucket, this boolean option will delete all contained objects. | `bool` | `false` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A map of key/value label pairs to assign to the bucket. | `map(string)` | `{}` | no |
| <a name="input_lifecycle_rule"></a> [lifecycle\_rule](#input\_lifecycle\_rule) | The bucket's lifecycle rules configuration. | <pre>map(object({<br>    action = object({<br>      type          = string<br>      storage_class = string<br>    })<br>    condition = object({<br>      age                        = number<br>      created_before             = string<br>      with_state                 = string<br>      matches_storage_class      = list(string)<br>      matches_prefix             = list(string)<br>      matches_suffix             = list(string)<br>      num_newer_versions         = number<br>      custom_time_before         = string<br>      days_since_custom_time     = string<br>      days_since_noncurrent_time = string<br>      noncurrent_time_before     = string<br>    })<br>  }))</pre> | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Location for the bucket: regional, dual-regional or multi-regional [GCS locations](https://cloud.google.com/storage/docs/locations). | `string` | n/a | yes |
| <a name="input_logging"></a> [logging](#input\_logging) | The bucket's Access & Storage Logs configuration. | <pre>object({<br>    log_bucket        = string<br>    log_object_prefix = string<br>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the bucket. | `string` | n/a | yes |
| <a name="input_predefined_acl"></a> [predefined\_acl](#input\_predefined\_acl) | The canned GCS ACL to apply. | `string` | `null` | no |
| <a name="input_public_access_prevention"></a> [public\_access\_prevention](#input\_public\_access\_prevention) | Prevents public access to a bucket. Acceptable values are 'inherited' or 'enforced' | `string` | `null` | no |
| <a name="input_requester_pays"></a> [requester\_pays](#input\_requester\_pays) | Enables Requester Pays on a storage bucket. | `bool` | `null` | no |
| <a name="input_retention_policy"></a> [retention\_policy](#input\_retention\_policy) | Configuration of the bucket's data retention policy for how long objects in the bucket should be retained. | <pre>object({<br>    is_locked        = bool<br>    retention_period = number<br>  })</pre> | `null` | no |
| <a name="input_role_bucket_access_control"></a> [role\_bucket\_access\_control](#input\_role\_bucket\_access\_control) | The access permission for the entity. | `string` | `null` | no |
| <a name="input_role_entity_acl"></a> [role\_entity\_acl](#input\_role\_entity\_acl) | List of role/entity pairs in the form "ROLE:entity". | `list(string)` | `null` | no |
| <a name="input_roles"></a> [roles](#input\_roles) | Roles to bind to the bucket | `map(set(string))` | `null` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | The Storage Class of the new bucket. | `string` | `"STANDARD"` | no |
| <a name="input_uniform_bucket_level_access"></a> [uniform\_bucket\_level\_access](#input\_uniform\_bucket\_level\_access) | Enables Uniform bucket-level access access to a bucket | `bool` | `null` | no |
| <a name="input_versioning"></a> [versioning](#input\_versioning) | The bucket's Versioning configuration. | `bool` | `null` | no |
| <a name="input_website"></a> [website](#input\_website) | Configuration if the bucket acts as a website. Structure is documented below. | <pre>object({<br>    main_page_suffix = string<br>    not_found_page   = string<br>  })</pre> | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->