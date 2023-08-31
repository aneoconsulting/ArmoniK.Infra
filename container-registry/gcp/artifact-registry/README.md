# Google Artifact Registry

The Google Artifact Registry provides a single location for storing and managing your packages and Docker container images.

This module creates a Google Artifact Registry of docker images with these possibilities :

* Enable or disable mutability.
* Add some rights for a list of users

<!-- Enable or disable the force delete -->
<!-- Choose the encryption type -->
<!-- Set a lifecycle policy -->

This module must be used with these constraints:

* Use the same availability zone to all the repositories.
* Give the image name and the tag of all the images

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
| [google_artifact_registry_repository.docker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository) | resource |
| [google_artifact_registry_repository_iam_member.artifact_registry_roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_member) | resource |
| [null_resource.copy_images](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_description"></a> [description](#input\_description) | Description of the registry | `string` | `""` | no |
| <a name="input_docker_images"></a> [docker\_images](#input\_docker\_images) | Docker container images to push inside the registry | <pre>map(object({<br>    image = string<br>    tag   = string<br>  }))</pre> | n/a | yes |
| <a name="input_iam_roles"></a> [iam\_roles](#input\_iam\_roles) | Assign role on the repository for a list of users | `map(set(string))` | `{}` | no |
| <a name="input_immutable_tags"></a> [immutable\_tags](#input\_immutable\_tags) | If the registry is a docker format then tags can be immutable (true or false) | `bool` | `true` | no |
| <a name="input_kms_key_name"></a> [kms\_key\_name](#input\_kms\_key\_name) | KMS key name to encrypt GCP repositories. Has the form: projects/{{my-project}}/locations/{{my-region}}/keyRings/{{my-kr}}/cryptoKeys/{{my-key}} | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels for the registry | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the registry to create | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_docker_repositories"></a> [docker\_repositories](#output\_docker\_repositories) | Docker repositories in Artifactory Registry created on GCP |
| <a name="output_kms_key_name"></a> [kms\_key\_name](#output\_kms\_key\_name) | KMS key name used to encrypt the registry |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | The associated service account created for artifact-registry. |
<!-- END_TF_DOCS -->