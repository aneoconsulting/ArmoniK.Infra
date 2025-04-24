<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.4.0 |
| <a name="requirement_mongodbatlas"></a> [mongodbatlas](#requirement\_mongodbatlas) | >= 1.10.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.36.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.2 |
| <a name="provider_mongodbatlas"></a> [mongodbatlas](#provider\_mongodbatlas) | 1.33.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_secret.mongodb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodb_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodb_atlas_certificates](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodb_user](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodbatlas_connection_string](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [local_sensitive_file.mongodb_client_certificate](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [mongodbatlas_database_user.admin](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/database_user) | resource |
| [null_resource.certificate_dependency](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.download_atlas_certificate](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.mongodb_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.mongodb_application_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.mongodb_admin_user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.mongodb_application_user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [mongodbatlas_advanced_cluster.aklocal](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/data-sources/advanced_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_atlas"></a> [atlas](#input\_atlas) | Atlas project parameters | <pre>object({<br/>    cluster_name = string<br/>    project_id   = string<br/>  })</pre> | n/a | yes |
| <a name="input_download_atlas_certificate"></a> [download\_atlas\_certificate](#input\_download\_atlas\_certificate) | Whether to automatically download the MongoDB Atlas CA certificate | `bool` | `false` | no |
| <a name="input_mongodb_atlas_private_key"></a> [mongodb\_atlas\_private\_key](#input\_mongodb\_atlas\_private\_key) | MongoDB Atlas private API key | `string` | n/a | yes |
| <a name="input_mongodb_atlas_public_key"></a> [mongodb\_atlas\_public\_key](#input\_mongodb\_atlas\_public\_key) | MongoDB Atlas public API key | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace where secrets will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ca_certificate"></a> [ca\_certificate](#output\_ca\_certificate) | MongoDB Atlas CA certificate path |
| <a name="output_certificate_mount_path"></a> [certificate\_mount\_path](#output\_certificate\_mount\_path) | Suggested path to mount the certificate in containers |
| <a name="output_certificate_secret"></a> [certificate\_secret](#output\_certificate\_secret) | Kubernetes secret containing the MongoDB Atlas certificate |
| <a name="output_connection_string"></a> [connection\_string](#output\_connection\_string) | MongoDB Atlas connection string |
| <a name="output_env"></a> [env](#output\_env) | Environment variables for MongoDB Atlas configuration |
| <a name="output_env_from_secret"></a> [env\_from\_secret](#output\_env\_from\_secret) | Environment variables from secrets for MongoDB Atlas configuration |
| <a name="output_host"></a> [host](#output\_host) | MongoDB Atlas host |
| <a name="output_port"></a> [port](#output\_port) | MongoDB Atlas port |
| <a name="output_url"></a> [url](#output\_url) | MongoDB Atlas connection URL |
| <a name="output_user_credentials"></a> [user\_credentials](#output\_user\_credentials) | User credentials of MongoDB Atlas |
<!-- END_TF_DOCS -->
