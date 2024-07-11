<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.7.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.4.0 |
| <a name="requirement_pkcs12"></a> [pkcs12](#requirement\_pkcs12) | >= 0.0.7 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.7.1 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.4.0 |
| <a name="provider_pkcs12"></a> [pkcs12](#provider\_pkcs12) | >= 0.0.7 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_config_map.activemq_configs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.activemq_jolokia_configs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.activemq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_secret.activemq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.activemq_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.activemq_certificate](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.activemq_client_certificate](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.activemq_user](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.activemq_user_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service.activemq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [local_file.activemq_jetty_xml_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.activemq_jolokia_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.activemq_xml_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_sensitive_file.activemq_client_certificate](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [pkcs12_from_pem.activemq_certificate](https://registry.terraform.io/providers/chilicat/pkcs12/latest/docs/resources/from_pem) | resource |
| [random_password.mq_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.mq_application_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.mq_keystore_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.mq_admin_user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.mq_application_user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_cert_request.activemq_cert_request](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_locally_signed_cert.activemq_certificate](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.activemq_private_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.root_activemq](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.root_activemq](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_activemq"></a> [activemq](#input\_activemq) | Parameters of ActiveMQ | <pre>object({<br>    image              = string<br>    tag                = string<br>    node_selector      = any<br>    image_pull_secrets = string<br>  })</pre> | n/a | yes |
| <a name="input_adapter_absolute_path"></a> [adapter\_absolute\_path](#input\_adapter\_absolute\_path) | The adapter's absolut path | `string` | `"/adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll"` | no |
| <a name="input_adapter_class_name"></a> [adapter\_class\_name](#input\_adapter\_class\_name) | Name of the adapter's class | `string` | `"ArmoniK.Core.Adapters.Amqp.QueueBuilder"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK storage resources | `string` | n/a | yes |
| <a name="input_path"></a> [path](#input\_path) | Path for mounting secrets | `string` | `"/amqp"` | no |
| <a name="input_queue_storage_adapter"></a> [queue\_storage\_adapter](#input\_queue\_storage\_adapter) | Name of the adapter's | `string` | `"ArmoniK.Adapters.Amqp.ObjectStorage"` | no |
| <a name="input_scheme"></a> [scheme](#input\_scheme) | The scheme for the AMQP | `string` | `"AMQPS"` | no |
| <a name="input_validity_period_hours"></a> [validity\_period\_hours](#input\_validity\_period\_hours) | Validity period of the certificate in hours | `string` | `"8760"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_adapter_absolute_path"></a> [adapter\_absolute\_path](#output\_adapter\_absolute\_path) | Absolute path for the queue adapter |
| <a name="output_adapter_class_name"></a> [adapter\_class\_name](#output\_adapter\_class\_name) | Class name for queue adapter |
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Endpoints of ActiveMQ |
| <a name="output_engine_type"></a> [engine\_type](#output\_engine\_type) | Engine type |
| <a name="output_env"></a> [env](#output\_env) | Elements to be set as environment variables |
| <a name="output_env_secret"></a> [env\_secret](#output\_env\_secret) | Secrets to be set as environment variables |
| <a name="output_host"></a> [host](#output\_host) | Host of ActiveMQ |
| <a name="output_mount_secret"></a> [mount\_secret](#output\_mount\_secret) | Secrets to be mounted as volumes |
| <a name="output_port"></a> [port](#output\_port) | Port of ActiveMQ |
| <a name="output_url"></a> [url](#output\_url) | URL of ActiveMQ |
| <a name="output_user_certificate"></a> [user\_certificate](#output\_user\_certificate) | User certificates of ActiveMQ |
| <a name="output_user_credentials"></a> [user\_credentials](#output\_user\_credentials) | User credentials of ActiveMQ |
| <a name="output_web_url"></a> [web\_url](#output\_web\_url) | Web URL of ActiveMQ |
<!-- END_TF_DOCS -->
