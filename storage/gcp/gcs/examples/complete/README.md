# GCS

To create a complete GCS:

```bash
terraform init
terraform plan
terraform apply
```

To delete all resource:

```bash
terraform destroy
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3.1 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.75.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | ~> 2.3.1 |
| <a name="provider_google"></a> [google](#provider\_google) | ~> 4.75.0 |
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.4.0 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.2.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_complete_gcs_bucket"></a> [complete\_gcs\_bucket](#module\_complete\_gcs\_bucket) | ../../../gcs | n/a |

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
| <a name="input_region"></a> [region](#input\_region) | The GCP region to deploy the GCS. | `string` | `"europe-west9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_control_domain"></a> [access\_control\_domain](#output\_access\_control\_domain) | The domain associated with the bucket access control. |
| <a name="output_access_control_email"></a> [access\_control\_email](#output\_access\_control\_email) | The email address associated with the bucket access control. |
| <a name="output_access_control_id"></a> [access\_control\_id](#output\_access\_control\_id) | An identifier for the bucket access control |
| <a name="output_acls"></a> [acls](#output\_acls) | The associated ACLs |
| <a name="output_iam_members"></a> [iam\_members](#output\_iam\_members) | The associated IAM policy |
| <a name="output_name"></a> [name](#output\_name) | Name of the bucket |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | The URI of the created bucket |
| <a name="output_url"></a> [url](#output\_url) | The base URL of the bucket, in the format gs://<bucket-name> |
<!-- END_TF_DOCS -->