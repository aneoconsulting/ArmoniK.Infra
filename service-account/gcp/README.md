# GCP service account for Pods

This module facilitates the creation of a GCP service account assigned with the "workLoadIdentityUser" role, along with
other necessary roles. Additionally, it establishes a Kubernetes service account that assumes the identity of the GCP
service account. This Kubernetes service account is meant to be associated with the pods within the GKE cluster.

This module performs the following actions:
* Create a GCP service account assigned with "workLoadIdentityUser" role.
* Add a list of IAM roles for the GCP service account.
* Create a kubernetes service account associated with the GCP service account.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.75.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.75.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.21.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_project_iam_member.workload_identity_sa_bindings](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.pods](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.pods](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [kubernetes_service_account.pods](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_automount_service_account_token"></a> [automount\_service\_account\_token](#input\_automount\_service\_account\_token) | To enable automatic mounting of the Kubernetes service account token. | `bool` | `true` | no |
| <a name="input_kubernetes_namespace"></a> [kubernetes\_namespace](#input\_kubernetes\_namespace) | Namespace within which name of the service account must be unique. | `string` | `"default"` | no |
| <a name="input_roles"></a> [roles](#input\_roles) | A list of roles to be added to the created service account. | `set(string)` | `[]` | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | Name of service account name. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubernetes_service_account_name"></a> [kubernetes\_service\_account\_name](#output\_kubernetes\_service\_account\_name) | Name of Kubernetes service account. |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace within which name of the service account must be unique. |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | The e-mail address of the GCP service account. |
| <a name="output_service_account_id"></a> [service\_account\_id](#output\_service\_account\_id) | The ID of the GCP service account. |
| <a name="output_service_account_name"></a> [service\_account\_name](#output\_service\_account\_name) | Name of GCP service account. |
| <a name="output_service_account_roles"></a> [service\_account\_roles](#output\_service\_account\_roles) | The IAM roles associated with the GCP service account. |
<!-- END_TF_DOCS -->