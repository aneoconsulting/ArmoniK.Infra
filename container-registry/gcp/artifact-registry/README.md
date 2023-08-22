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
| [google_artifact_registry_repository_iam_binding.binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_binding) | resource |
| [google_service_account.service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [null_resource.copy_images](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_service_account"></a> [create\_service\_account](#input\_create\_service\_account) | Set to true if you need the service account for artifact registry to be created also. (Default: false) | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the registry | `string` | `""` | no |
| <a name="input_docker_images"></a> [docker\_images](#input\_docker\_images) | Docker container images to push inside the registry | <pre>map(object({<br>    image = string<br>    tag   = string<br>  }))</pre> | n/a | yes |
| <a name="input_iam_bindings"></a> [iam\_bindings](#input\_iam\_bindings) | Assign role on the repository for a list of users | `map(list(string))` | `{}` | no |
| <a name="input_immutable_tags"></a> [immutable\_tags](#input\_immutable\_tags) | If the registry is a docker format then tags can be immutable (true or false) | `bool` | `true` | no |
| <a name="input_kms_key_name"></a> [kms\_key\_name](#input\_kms\_key\_name) | KMS key name to encrypt GCP repositories. Has the form: projects/{{my-project}}/locations/{{my-region}}/keyRings/{{my-kr}}/cryptoKeys/{{my-key}} | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels for the registry | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the registry to create | `string` | n/a | yes |
| <a name="input_service_account_description"></a> [service\_account\_description](#input\_service\_account\_description) | A text description of the service account. | `string` | `null` | no |
| <a name="input_service_account_display_name"></a> [service\_account\_display\_name](#input\_service\_account\_display\_name) | The display name for the service account. Can be updated without creating a new resource. | `string` | `null` | no |
| <a name="input_service_account_id"></a> [service\_account\_id](#input\_service\_account\_id) | The account id that is used to generate the service account email address and a stable unique id. Only if var.create\_service\_account is set to true. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_docker_repositories"></a> [docker\_repositories](#output\_docker\_repositories) | Docker repositories in Artifactory Registry created on GCP |
| <a name="output_kms_key_name"></a> [kms\_key\_name](#output\_kms\_key\_name) | KMS key name used to encrypt the registry |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | The associated service account created for artifact-registry. |
<!-- END_TF_DOCS -->