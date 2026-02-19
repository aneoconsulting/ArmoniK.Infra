<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.10.1, < 3.0.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >=1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.10.1, < 3.0.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >=1.14.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.21.1 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.cluster](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_secret.application_user_password](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodb_connection_string](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodb_monitoring_connection_string](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_storage_class.configsvr](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [kubernetes_storage_class.shards](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [random_password.app_user_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [kubernetes_secret.percona_cluster_secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Parameters for the Percona Server for MongoDB cluster | <pre>object({<br/>    helm_chart_repository = optional(string, "https://percona.github.io/percona-helm-charts/")<br/>    helm_chart_name       = optional(string, "psmdb-db")<br/>    helm_chart_version    = optional(string)<br/>    image                 = optional(string, "percona/percona-server-mongodb")<br/>    tag                   = optional(string)<br/>    database_name         = optional(string, "database")<br/>    replicas              = optional(number, 1)<br/>    node_selector         = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used for the helm chart release and the associated resources | `string` | `"percona-mongodb"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK resources | `string` | `"default"` | no |
| <a name="input_operator"></a> [operator](#input\_operator) | Parameters for the Percona PSMDB Operator deployment | <pre>object({<br/>    helm_chart_repository = optional(string, "https://percona.github.io/percona-helm-charts/")<br/>    helm_chart_name       = optional(string, "psmdb-operator")<br/>    helm_chart_version    = optional(string)<br/>    image                 = optional(string, "percona/percona-server-mongodb-operator")<br/>    tag                   = optional(string)<br/>    node_selector         = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_persistence"></a> [persistence](#input\_persistence) | Persistence parameters for MongoDB pods | <pre>object({<br/>    shards = optional(object({<br/>      storage_size        = optional(string, "8Gi")<br/>      storage_class_name  = optional(string) # Use existing StorageClass<br/>      storage_provisioner = optional(string) # Or create one<br/>      reclaim_policy      = optional(string, "Delete")<br/>      volume_binding_mode = optional(string, "WaitForFirstConsumer")<br/>      access_modes        = optional(list(string), ["ReadWriteOnce"])<br/>      parameters          = optional(map(string), {})<br/>    }), {})<br/><br/>    configsvr = optional(object({<br/>      storage_size        = optional(string, "3Gi")<br/>      storage_class_name  = optional(string)<br/>      storage_provisioner = optional(string)<br/>      reclaim_policy      = optional(string, "Delete")<br/>      volume_binding_mode = optional(string, "WaitForFirstConsumer")<br/>      access_modes        = optional(list(string), ["ReadWriteOnce"])<br/>      parameters          = optional(map(string), {})<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Resource requests and limits per component | <pre>object({<br/>    shards = optional(object({<br/>      limits   = optional(map(string))<br/>      requests = optional(map(string))<br/>    }), {})<br/>    configsvr = optional(object({<br/>      limits   = optional(map(string))<br/>      requests = optional(map(string))<br/>    }), {})<br/>    mongos = optional(object({<br/>      limits   = optional(map(string))<br/>      requests = optional(map(string))<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_sharding"></a> [sharding](#input\_sharding) | Sharding configuration. Set to null to disable sharding. | <pre>object({<br/>    enabled = optional(bool, false)<br/>    configsvr = optional(object({<br/>      replicas      = optional(number, 1)<br/>      node_selector = optional(map(string), {})<br/>    }), {})<br/>    mongos = optional(object({<br/>      replicas      = optional(number, 1)<br/>      node_selector = optional(map(string), {})<br/>    }), {})<br/>  })</pre> | `null` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Timeout in seconds for the helm release creation | `number` | `600` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Endpoints of MongoDB |
| <a name="output_env"></a> [env](#output\_env) | Elements to be set as environment variables |
| <a name="output_env_from_secret"></a> [env\_from\_secret](#output\_env\_from\_secret) | Environment variables from secrets |
| <a name="output_host"></a> [host](#output\_host) | Hostname or IP address of MongoDB server |
| <a name="output_mount_secret"></a> [mount\_secret](#output\_mount\_secret) | Secrets to be mounted as volumes |
| <a name="output_number_of_replicas"></a> [number\_of\_replicas](#output\_number\_of\_replicas) | Number of replicas in the MongoDB replica set |
| <a name="output_port"></a> [port](#output\_port) | Port of MongoDB server |
| <a name="output_url"></a> [url](#output\_url) | URL of MongoDB server |
| <a name="output_user_credentials"></a> [user\_credentials](#output\_user\_credentials) | User credentials of MongoDB |
<!-- END_TF_DOCS -->