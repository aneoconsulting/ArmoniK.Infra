<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.12.1, < 3.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.7.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.4.0 |
| <a name="requirement_pkcs12"></a> [pkcs12](#requirement\_pkcs12) | >= 0.0.7 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.12.1, < 3.0.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.7.1 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.4.0 |
| <a name="provider_pkcs12"></a> [pkcs12](#provider\_pkcs12) | >= 0.0.7 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.rabbitmq](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_secret.rabbitmq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.rabbitmq_certificate](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.rabbitmq_client_certificate](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.rabbitmq_user](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.rabbitmq_user_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [local_sensitive_file.rabbitmq_client_certificate](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [pkcs12_from_pem.rabbitmq_certificate](https://registry.terraform.io/providers/chilicat/pkcs12/latest/docs/resources/from_pem) | resource |
| [random_password.mq_application_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.mq_keystore_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.mq_application_user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [kubernetes_secret.rabbitmq_certs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [kubernetes_service.rabbitmq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adapter_absolute_path"></a> [adapter\_absolute\_path](#input\_adapter\_absolute\_path) | The adapter's absolut path | `string` | `"/adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll"` | no |
| <a name="input_adapter_class_name"></a> [adapter\_class\_name](#input\_adapter\_class\_name) | Name of the adapter's class | `string` | `"ArmoniK.Core.Adapters.Amqp.QueueBuilder"` | no |
| <a name="input_helm_chart_repository"></a> [helm\_chart\_repository](#input\_helm\_chart\_repository) | Path to helm chart repository for RabbitMQ | `string` | n/a | yes |
| <a name="input_helm_chart_version"></a> [helm\_chart\_version](#input\_helm\_chart\_version) | Version of chart helm for RabbitMQ | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | image for the rabbirmq to be used | `string` | `"bitnamilegacy/rabbitmq"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the queue storage | `string` | `"rabbitmq"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace for rabbitmq | `string` | n/a | yes |
| <a name="input_path"></a> [path](#input\_path) | Path for mounting secrets | `string` | `"/amqp"` | no |
| <a name="input_queue_storage_adapter"></a> [queue\_storage\_adapter](#input\_queue\_storage\_adapter) | Name of the adapter's | `string` | `"ArmoniK.Adapters.Amqp.ObjectStorage"` | no |
| <a name="input_scheme"></a> [scheme](#input\_scheme) | The scheme for the AMQP | `string` | `"AMQPS"` | no |
| <a name="input_tag"></a> [tag](#input\_tag) | tag for the image | `string` | `"3.12.12-debian-11-r21"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_adapter_absolute_path"></a> [adapter\_absolute\_path](#output\_adapter\_absolute\_path) | Absolute path for the queue adapter |
| <a name="output_adapter_class_name"></a> [adapter\_class\_name](#output\_adapter\_class\_name) | Class name for queue adapter |
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Endpoints of RabbitMQ |
| <a name="output_engine_type"></a> [engine\_type](#output\_engine\_type) | Engine type |
| <a name="output_env"></a> [env](#output\_env) | Elements to be set as environment variables |
| <a name="output_env_secret"></a> [env\_secret](#output\_env\_secret) | Secrets to be set as environment variables |
| <a name="output_host"></a> [host](#output\_host) | Host of RabbitMQ |
| <a name="output_mount_secret"></a> [mount\_secret](#output\_mount\_secret) | Secrets to be mounted as volumes |
| <a name="output_port"></a> [port](#output\_port) | Port of RabbitMQ |
| <a name="output_url"></a> [url](#output\_url) | URL of RabbitMQ |
| <a name="output_user_certificate"></a> [user\_certificate](#output\_user\_certificate) | User certificates of RabbitMQ |
| <a name="output_user_credentials"></a> [user\_credentials](#output\_user\_credentials) | User credentials of RabbitMQ |
| <a name="output_web_url"></a> [web\_url](#output\_web\_url) | Web URL of RabbitMQ |
<!-- END_TF_DOCS -->