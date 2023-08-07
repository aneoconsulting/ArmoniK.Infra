# Google Artifact Registry

To create a Google Artifact Registry:

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
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.75.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_simple_artifact_registry"></a> [simple\_artifact\_registry](#module\_simple\_artifact\_registry) | ../../../artifact-registry | n/a |

## Resources

| Name | Type |
|------|------|
| [null_resource.timestamp](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [external_external.static_timestamp](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | The GCP region to deploy the Artifact registry | `string` | `"europe-west9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_docker_repositories"></a> [docker\_repositories](#output\_docker\_repositories) | Docker repositories in Artifactory Registry created on GCP |
| <a name="output_kms_key_name"></a> [kms\_key\_name](#output\_kms\_key\_name) | KMS key name used to encrypt the registry |
<!-- END_TF_DOCS -->