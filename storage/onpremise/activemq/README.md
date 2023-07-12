<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.21.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | 2.4.0 |
| <a name="requirement_pkcs12"></a> [pkcs12](#requirement\_pkcs12) | 0.0.7 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.5.1 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.21.1 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.4.0 |
| <a name="provider_pkcs12"></a> [pkcs12](#provider\_pkcs12) | 0.0.7 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.5.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_config_map.activemq_configs](https://registry.terraform.io/providers/hashicorp/kubernetes/2.21.1/docs/resources/config_map) | resource |
| [kubernetes_config_map.activemq_jolokia_configs](https://registry.terraform.io/providers/hashicorp/kubernetes/2.21.1/docs/resources/config_map) | resource |
| [kubernetes_deployment.activemq](https://registry.terraform.io/providers/hashicorp/kubernetes/2.21.1/docs/resources/deployment) | resource |
| [kubernetes_secret.activemq](https://registry.terraform.io/providers/hashicorp/kubernetes/2.21.1/docs/resources/secret) | resource |
| [kubernetes_secret.activemq_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/2.21.1/docs/resources/secret) | resource |
| [kubernetes_secret.activemq_certificate](https://registry.terraform.io/providers/hashicorp/kubernetes/2.21.1/docs/resources/secret) | resource |
| [kubernetes_secret.activemq_client_certificate](https://registry.terraform.io/providers/hashicorp/kubernetes/2.21.1/docs/resources/secret) | resource |
| [kubernetes_secret.activemq_user](https://registry.terraform.io/providers/hashicorp/kubernetes/2.21.1/docs/resources/secret) | resource |
| [kubernetes_service.activemq](https://registry.terraform.io/providers/hashicorp/kubernetes/2.21.1/docs/resources/service) | resource |
| [local_file.activemq_jetty_xml_file](https://registry.terraform.io/providers/hashicorp/local/2.4.0/docs/resources/file) | resource |
| [local_file.activemq_jolokia_file](https://registry.terraform.io/providers/hashicorp/local/2.4.0/docs/resources/file) | resource |
| [local_file.activemq_xml_file](https://registry.terraform.io/providers/hashicorp/local/2.4.0/docs/resources/file) | resource |
| [local_sensitive_file.activemq_client_certificate](https://registry.terraform.io/providers/hashicorp/local/2.4.0/docs/resources/sensitive_file) | resource |
| [pkcs12_from_pem.activemq_certificate](https://registry.terraform.io/providers/chilicat/pkcs12/0.0.7/docs/resources/from_pem) | resource |
| [random_password.mq_admin_password](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/password) | resource |
| [random_password.mq_application_password](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/password) | resource |
| [random_password.mq_keystore_password](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/password) | resource |
| [random_string.mq_admin_user](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/string) | resource |
| [random_string.mq_application_user](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/string) | resource |
| [tls_cert_request.activemq_cert_request](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/cert_request) | resource |
| [tls_locally_signed_cert.activemq_certificate](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.activemq_private_key](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/private_key) | resource |
| [tls_private_key.root_activemq](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/private_key) | resource |
| [tls_self_signed_cert.root_activemq](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/self_signed_cert) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_active_deadline_seconds"></a> [active\_deadline\_seconds](#input\_active\_deadline\_seconds) | Optional duration in seconds the pod may be active on the node relative to StartTime before the system will actively try to mark it failed and kill associated containers. Value must be a positive integer | `number` | `null` | no |
| <a name="input_image"></a> [image](#input\_image) | images of services | `string` | `"symptoma/activemq"` | no |
| <a name="input_image_pull_secrets"></a> [image\_pull\_secrets](#input\_image\_pull\_secrets) | (Optional) Specify list of pull secrets | `map(string)` | `{}` | no |
| <a name="input_min_ready_seconds"></a> [min\_ready\_seconds](#input\_min\_ready\_seconds) | Field that specifies the minimum number of seconds for which a newly created Pod should be ready without any of its containers crashing, for it to be considered available | `number` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | value | `string` | `"activemq"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK storage resources | `string` | n/a | yes |
| <a name="input_node_name"></a> [node\_name](#input\_node\_name) | (Optional) NodeName is a request to schedule this pod onto a specific node. If it is non-empty, the scheduler simply schedules this pod onto that node, assuming that it fits resource requirements | `string` | `null` | no |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Specify node selector for pod | `map(string)` | `{}` | no |
| <a name="input_priority_class_name"></a> [priority\_class\_name](#input\_priority\_class\_name) | Indicates the pod's priority. Requires an existing priority class name resource if not 'system-node-critical' and 'system-cluster-critical' | `string` | `""` | no |
| <a name="input_progress_deadline_seconds"></a> [progress\_deadline\_seconds](#input\_progress\_deadline\_seconds) | The maximum time in seconds for a deployment to make progress before it is considered to be failed | `number` | `600` | no |
| <a name="input_restart_policy"></a> [restart\_policy](#input\_restart\_policy) | Restart policy for all containers within the pod. One of Always, OnFailure, Never | `string` | `"Always"` | no |
| <a name="input_revision_history_limit"></a> [revision\_history\_limit](#input\_revision\_history\_limit) | The number of revision hitory to keep. | `number` | `10` | no |
| <a name="input_rolling_update"></a> [rolling\_update](#input\_rolling\_update) | Rolling update config params. Present only if strategy\_update = RollingUpdate | `object({ max_surge = optional(string), max_unavailable = optional(string) })` | `{}` | no |
| <a name="input_security_context"></a> [security\_context](#input\_security\_context) | (Optional) SecurityContext holds pod-level security attributes and common container settings | `list(any)` | `[]` | no |
| <a name="input_strategy_update"></a> [strategy\_update](#input\_strategy\_update) | Rolling update config params. Present only if strategy\_update = RollingUpdate | `string` | `null` | no |
| <a name="input_tag"></a> [tag](#input\_tag) | tag of images | `string` | `"5.17.0"` | no |
| <a name="input_termination_grace_period_seconds"></a> [termination\_grace\_period\_seconds](#input\_termination\_grace\_period\_seconds) | Duration in seconds the pod needs to terminate gracefully | `number` | `20` | no |
| <a name="input_toleration"></a> [toleration](#input\_toleration) | (Optional) Pod node tolerations | <pre>list(object({<br>    effect             = optional(string)<br>    key                = optional(string)<br>    operator           = optional(string)<br>    toleration_seconds = optional(string)<br>    value              = optional(string)<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_adapter_absolute_path"></a> [adapter\_absolute\_path](#output\_adapter\_absolute\_path) | Absolute path for the queue adapter |
| <a name="output_adapter_class_name"></a> [adapter\_class\_name](#output\_adapter\_class\_name) | Class name for queue adapter |
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Endpoints of ActiveMQ |
| <a name="output_engine_type"></a> [engine\_type](#output\_engine\_type) | Engine type |
| <a name="output_host"></a> [host](#output\_host) | Host of ActiveMQ |
| <a name="output_port"></a> [port](#output\_port) | Port of ActiveMQ |
| <a name="output_url"></a> [url](#output\_url) | URL of ActiveMQ |
| <a name="output_user_certificate"></a> [user\_certificate](#output\_user\_certificate) | User certificates of ActiveMQ |
| <a name="output_user_credentials"></a> [user\_credentials](#output\_user\_credentials) | User credentials of ActiveMQ |
| <a name="output_web_url"></a> [web\_url](#output\_web\_url) | Web URL of ActiveMQ |
<!-- END_TF_DOCS -->
