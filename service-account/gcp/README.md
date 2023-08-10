This module facilitates the creation of a GCP service account assigned with the "workLoadIdentityUser" role, along with other necessary roles. Additionally, it establishes a Kubernetes service account that assumes the identity of the GCP service account. This Kubernetes service account is meant to be associated with the pods within the GKE cluster.

## List of inputs

- Kubernetes namespace
- Name of GCP service account
- Name of kubernetes service account
- Project ID
- List of roles

## List of outputs

- Kubernetes namespace
- GCP and Kubernetes service accounts names


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
| [kubernetes_namespace.pods](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_service_account.pods](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_K8s_namespace"></a> [K8s\_namespace](#input\_K8s\_namespace) | Namespace within which name of the service account must be unique | `string` | `null` | no |
| <a name="input_automount_service_account_token"></a> [automount\_service\_account\_token](#input\_automount\_service\_account\_token) | To enable automatic mounting of the service account token | `bool` | `true` | no |
| <a name="input_gcp_sa_name"></a> [gcp\_sa\_name](#input\_gcp\_sa\_name) | GCP service account name | `string` | `null` | no |
| <a name="input_k8s_sa_name"></a> [k8s\_sa\_name](#input\_k8s\_sa\_name) | Name of Kubernetes service account | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | `null` | no |
| <a name="input_roles"></a> [roles](#input\_roles) | A list of roles to be added to the created service account | `set(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gcp_sa_name"></a> [gcp\_sa\_name](#output\_gcp\_sa\_name) | Name of GCP service account |
| <a name="output_k8s_sa_name"></a> [k8s\_sa\_name](#output\_k8s\_sa\_name) | Name of Kubernetes service account |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace within which name of the service account must be unique |
<!-- END_TF_DOCS -->