<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.7.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.7.1 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_deployment.minio](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_secret.minio](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.s3_user](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.s3_user_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service.minio](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [random_password.minio_application_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.minio_application_user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adapter_absolute_path"></a> [adapter\_absolute\_path](#input\_adapter\_absolute\_path) | The adapter's absolute path | `string` | `"/adapters/object/s3/ArmoniK.Core.Adapters.S3.dll"` | no |
| <a name="input_adapter_class_name"></a> [adapter\_class\_name](#input\_adapter\_class\_name) | Name of the adapter's class | `string` | `"ArmoniK.Core.Adapters.S3.ObjectBuilder"` | no |
| <a name="input_minio"></a> [minio](#input\_minio) | Parameters of S3 payload storage | <pre>object({<br>    image              = string<br>    tag                = string<br>    image_pull_secrets = string<br>    host               = string<br>    bucket_name        = string<br>    node_selector      = any<br>  })</pre> | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK storage resources | `string` | n/a | yes |
| <a name="input_object_storage_adapter"></a> [object\_storage\_adapter](#input\_object\_storage\_adapter) | Name of the ArmoniK adapter to use for the storage | `string` | `"ArmoniK.Adapters.S3.ObjectStorage"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the MinIO bucket |
| <a name="output_console_url"></a> [console\_url](#output\_console\_url) | Web YRL of MinIO |
| <a name="output_env"></a> [env](#output\_env) | Elements to be set as environment variables |
| <a name="output_env_secret"></a> [env\_secret](#output\_env\_secret) | Secrets to be set as environment variables |
| <a name="output_host"></a> [host](#output\_host) | Host of MinIO |
| <a name="output_login"></a> [login](#output\_login) | Username of MinIO |
| <a name="output_must_force_path_style"></a> [must\_force\_path\_style](#output\_must\_force\_path\_style) | Boolean to force path style |
| <a name="output_password"></a> [password](#output\_password) | Password of MinIO |
| <a name="output_port"></a> [port](#output\_port) | Port of MinIO |
| <a name="output_url"></a> [url](#output\_url) | URL of MinIO |
<!-- END_TF_DOCS -->
