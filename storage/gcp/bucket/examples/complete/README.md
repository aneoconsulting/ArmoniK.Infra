<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.75.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_complex_bucket_example"></a> [complex\_bucket\_example](#module\_complex\_bucket\_example) | ../../../bucket | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | The GCP region to deploy the subnets in | `string` | `"europe-west9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acls_bucket"></a> [acls\_bucket](#output\_acls\_bucket) | The associated ACLS |
| <a name="output_bucket"></a> [bucket](#output\_bucket) | bucket created on GCP |
| <a name="output_iam_bucket"></a> [iam\_bucket](#output\_iam\_bucket) | The associated IAM policy |
<!-- END_TF_DOCS -->