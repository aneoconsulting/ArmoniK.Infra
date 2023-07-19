Artifact Registry provides a single location for storing and managing your packages and Docker container images.

This module creates an artifact registry of docker images with these possibilities :

Enable or disable mutability
Add some rights for a list of users
<!-- Enable or disable the force delete -->
<!-- Choose the encryption type -->
<!-- Set a lifecycle policy -->

This module must be used with these constraints:

Use the same availability zone to all the repositories
Give the image name and the tag of all the images
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.51.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.51.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_artifact_registry_repository.artifact_registry_docker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository) | resource |
| [google_artifact_registry_repository_iam_binding.binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_binding) | resource |
| [null_resource.gcp_copy_images](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_credentials_file"></a> [credentials\_file](#input\_credentials\_file) | Path to credential json file | `string` | n/a | yes |
| <a name="input_immutable_tags"></a> [immutable\_tags](#input\_immutable\_tags) | If the registry is a docker format then tags can be immutable (true or false) | `bool` | `null` | no |
| <a name="input_kms_key"></a> [kms\_key](#input\_kms\_key) | KMS to encrypt GCP repositories | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project ID on which to create artifact registry (AR) | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region of the project | `string` | n/a | yes |
| <a name="input_registry_description"></a> [registry\_description](#input\_registry\_description) | Description of the registry | `string` | n/a | yes |
| <a name="input_registry_iam"></a> [registry\_iam](#input\_registry\_iam) | Assign role on the repository for a list of users | `map(list(string))` | `null` | no |
| <a name="input_registry_images"></a> [registry\_images](#input\_registry\_images) | Images to push inside the registry | <pre>map(object({<br>    image = string<br>    tag   = string<br>  }))</pre> | n/a | yes |
| <a name="input_registry_labels"></a> [registry\_labels](#input\_registry\_labels) | Labels for the registry | `map(string)` | `null` | no |
| <a name="input_registry_name"></a> [registry\_name](#input\_registry\_name) | Name of the registry to create | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | Zone of the project | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_artifact_registry"></a> [artifact\_registry](#output\_artifact\_registry) | Registry created on GCP |
| <a name="output_kms_key"></a> [kms\_key](#output\_kms\_key) | KMS used for registry |
<!-- END_TF_DOCS -->