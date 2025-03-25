# GCS

To create a simple GCS:

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
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 6.16.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_simple_bucket"></a> [simple\_bucket](#module\_simple\_bucket) | ../../../gcs | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The GCP region to deploy the GCS | `string` | `"europe-west9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name"></a> [name](#output\_name) | Name of the bucket |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | The URI of the created bucket |
| <a name="output_url"></a> [url](#output\_url) | The base URL of the bucket, in the format gs://<bucket-name> |
<!-- END_TF_DOCS -->