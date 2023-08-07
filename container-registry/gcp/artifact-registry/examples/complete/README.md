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

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_complete_artifact_registry"></a> [complete\_artifact\_registry](#module\_complete\_artifact\_registry) | ../../../artifact-registry | n/a |

## Resources

No resources.

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