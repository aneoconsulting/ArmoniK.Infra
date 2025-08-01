<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.10.1, < 3.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.10.1, < 3.0.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.21.1 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.4.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.mongodb](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_secret.mongodb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodb_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodb_connection_string](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodb_monitoring_connection_string](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodb_user](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_storage_class.mongodb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [local_sensitive_file.mongodb_client_certificate](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [random_password.mongodb_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.mongodb_application_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.mongodb_monitoring_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.mongodb_admin_user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.mongodb_application_user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.mongodb_monitoring_user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [kubernetes_secret.mongodb_certificates](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_arbiter_resources"></a> [arbiter\_resources](#input\_arbiter\_resources) | CPU and Memory limits and requests for MongoDB arbiter | <pre>object({<br/>    limits   = optional(map(string))<br/>    requests = optional(map(string))<br/>  })</pre> | `{}` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels for the Kubernetes StatefulSet to be deployed | `map(string)` | <pre>{<br/>  "app": "storage",<br/>  "type": "table"<br/>}</pre> | no |
| <a name="input_mongodb"></a> [mongodb](#input\_mongodb) | Parameters of the MongoDB deployment | <pre>object({<br/>    databases_names       = optional(list(string), ["database"])<br/>    helm_chart_repository = optional(string, "oci://registry-1.docker.io/bitnamicharts")<br/>    helm_chart_name       = optional(string, "mongodb")<br/>    helm_chart_version    = string<br/>    image                 = optional(string, "bitnami/mongodb")<br/>    image_pull_secrets    = optional(any, []) # can be a string or a list of strings<br/>    node_selector         = optional(map(string), {})<br/>    registry              = optional(string)<br/>    replicas              = optional(number, 1)<br/>    tag                   = string<br/>  })</pre> | n/a | yes |
| <a name="input_mongodb_resources"></a> [mongodb\_resources](#input\_mongodb\_resources) | CPU and Memory limits and requests for MongoDB | <pre>object({<br/>    limits   = optional(map(string))<br/>    requests = optional(map(string))<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used for the helm chart release and the associated resources | `string` | `"mongodb-armonik"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK resources | `string` | `"default"` | no |
| <a name="input_persistent_volume"></a> [persistent\_volume](#input\_persistent\_volume) | Persistent Volume parameters for MongoDB pods | <pre>object({<br/>    access_mode         = optional(list(string), ["ReadWriteOnce"])<br/>    reclaim_policy      = optional(string, "Delete")<br/>    storage_provisioner = optional(string)<br/>    volume_binding_mode = optional(string, "WaitForFirstConsumer")<br/>    parameters          = optional(map(string), {})<br/><br/>    # Resources for PVC<br/>    resources = optional(object({<br/>      limits = optional(object({<br/>        storage = string<br/>      }))<br/>      requests = optional(object({<br/>        storage = string<br/>      }))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_security_context"></a> [security\_context](#input\_security\_context) | Security context for MongoDB pods | <pre>object({<br/>    run_as_user = number<br/>    fs_group    = number<br/>  })</pre> | <pre>{<br/>  "fs_group": 999,<br/>  "run_as_user": 999<br/>}</pre> | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Timeout limit in seconds per replica for the helm release creation | `number` | `480` | no |
| <a name="input_validity_period_hours"></a> [validity\_period\_hours](#input\_validity\_period\_hours) | Validity period of the TLS certificate in hours | `string` | `"8760"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Endpoints of MongoDB |
| <a name="output_env"></a> [env](#output\_env) | Elements to be set as environment variables |
| <a name="output_env_from_secret"></a> [env\_from\_secret](#output\_env\_from\_secret) | Environment variables from secrets |
| <a name="output_host"></a> [host](#output\_host) | Hostname or IP address of MongoDB server |
| <a name="output_mount_secret"></a> [mount\_secret](#output\_mount\_secret) | Secrets to be mounted as volumes |
| <a name="output_number_of_replicas"></a> [number\_of\_replicas](#output\_number\_of\_replicas) | Number of replicas of MongoDB |
| <a name="output_port"></a> [port](#output\_port) | Port of MongoDB server |
| <a name="output_unused_variables"></a> [unused\_variables](#output\_unused\_variables) | Map of variables that are not used yet but might be in the future |
| <a name="output_url"></a> [url](#output\_url) | URL of MongoDB server |
| <a name="output_user_credentials"></a> [user\_credentials](#output\_user\_credentials) | User credentials of MongoDB |
<!-- END_TF_DOCS -->
