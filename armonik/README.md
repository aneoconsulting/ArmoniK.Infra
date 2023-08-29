<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.10.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.1.0 |
| <a name="requirement_pkcs12"></a> [pkcs12](#requirement\_pkcs12) | >= 0.0.7 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.10.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.21.1 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.1.0 |
| <a name="provider_pkcs12"></a> [pkcs12](#provider\_pkcs12) | >= 0.0.7 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0.4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_admin_0_8_gui_endpoint"></a> [admin\_0\_8\_gui\_endpoint](#module\_admin\_0\_8\_gui\_endpoint) | ../utils/service-ip | n/a |
| <a name="module_admin_0_9_gui_endpoint"></a> [admin\_0\_9\_gui\_endpoint](#module\_admin\_0\_9\_gui\_endpoint) | ../utils/service-ip | n/a |
| <a name="module_admin_gui_endpoint"></a> [admin\_gui\_endpoint](#module\_admin\_gui\_endpoint) | ../utils/service-ip | n/a |
| <a name="module_control_plane_endpoint"></a> [control\_plane\_endpoint](#module\_control\_plane\_endpoint) | ../utils/service-ip | n/a |
| <a name="module_ingress_endpoint"></a> [ingress\_endpoint](#module\_ingress\_endpoint) | ../utils/service-ip | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.keda_hpa_compute_plane](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.keda_hpa_control_plane](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_config_map.authmongo](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.compute_plane_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.control_plane_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.core_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.log_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.polling_agent_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.static](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.worker_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_cron_job_v1.partitions_in_database](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cron_job_v1) | resource |
| [kubernetes_deployment.admin_0_8_gui](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.admin_0_9_gui](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.admin_gui](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.compute_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_job.authentication_in_database](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/job) | resource |
| [kubernetes_job.partitions_in_database](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/job) | resource |
| [kubernetes_secret.ingress_certificate](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.ingress_client_certificate](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.ingress_client_certificate_authority](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service.admin_0_8_gui](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service.admin_0_9_gui](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service.admin_gui](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service.control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service.ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [local_file.ingress_conf_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_sensitive_file.ingress_ca](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [local_sensitive_file.ingress_client_ca](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [local_sensitive_file.ingress_client_crt](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [local_sensitive_file.ingress_client_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [local_sensitive_file.ingress_client_p12](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [local_sensitive_file.initial_auth_config](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [pkcs12_from_pem.ingress_client_pkcs12](https://registry.terraform.io/providers/chilicat/pkcs12/latest/docs/resources/from_pem) | resource |
| [random_string.common_name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_cert_request.ingress_cert_request](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_cert_request.ingress_client_cert_request](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_locally_signed_cert.ingress_certificate](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_locally_signed_cert.ingress_client_certificate](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.client_root_ingress](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.ingress_client_private_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.ingress_private_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.root_ingress](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.client_root_ingress](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [tls_self_signed_cert.root_ingress](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [kubernetes_config_map.dns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/config_map) | data source |
| [kubernetes_secret.deployed_object_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [kubernetes_secret.deployed_queue_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [kubernetes_secret.deployed_table_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [kubernetes_secret.fluent_bit](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [kubernetes_secret.grafana](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [kubernetes_secret.metrics_exporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [kubernetes_secret.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [kubernetes_secret.seq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [kubernetes_secret.shared_storage](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/secret) | data source |
| [tls_certificate.certificate_data](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_0_8_gui"></a> [admin\_0\_8\_gui](#input\_admin\_0\_8\_gui) | Parameters of the admin GUI v0.8 | <pre>object({<br>    api = object({<br>      name  = string<br>      image = string<br>      tag   = string<br>      port  = number<br>      limits = object({<br>        cpu    = string<br>        memory = string<br>      })<br>      requests = object({<br>        cpu    = string<br>        memory = string<br>      })<br>    })<br>    app = object({<br>      name  = string<br>      image = string<br>      tag   = string<br>      port  = number<br>      limits = object({<br>        cpu    = string<br>        memory = string<br>      })<br>      requests = object({<br>        cpu    = string<br>        memory = string<br>      })<br>    })<br>    service_type       = string<br>    replicas           = number<br>    image_pull_policy  = string<br>    image_pull_secrets = string<br>    node_selector      = any<br>  })</pre> | `null` | no |
| <a name="input_admin_0_9_gui"></a> [admin\_0\_9\_gui](#input\_admin\_0\_9\_gui) | Parameters of the admin GUI v0.9 | <pre>object({<br>    name  = string<br>    image = string<br>    tag   = string<br>    port  = number<br>    limits = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    requests = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    service_type       = string<br>    replicas           = number<br>    image_pull_policy  = string<br>    image_pull_secrets = string<br>    node_selector      = any<br>  })</pre> | `null` | no |
| <a name="input_admin_gui"></a> [admin\_gui](#input\_admin\_gui) | Parameters of the admin GUI | <pre>object({<br>    name  = string<br>    image = string<br>    tag   = string<br>    port  = number<br>    limits = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    requests = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    service_type       = string<br>    replicas           = number<br>    image_pull_policy  = string<br>    image_pull_secrets = string<br>    node_selector      = any<br>  })</pre> | `null` | no |
| <a name="input_authentication"></a> [authentication](#input\_authentication) | Authentication behavior | <pre>object({<br>    name                    = string<br>    image                   = string<br>    tag                     = string<br>    image_pull_policy       = string<br>    image_pull_secrets      = string<br>    node_selector           = any<br>    authentication_datafile = string<br>    require_authentication  = bool<br>    require_authorization   = bool<br>  })</pre> | n/a | yes |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Name for chart | `string` | `"keda-hpa"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Version for chart | `string` | `"0.1.0"` | no |
| <a name="input_charts_repository"></a> [charts\_repository](#input\_charts\_repository) | Path to the charts repository | `string` | `"../charts"` | no |
| <a name="input_compute_plane"></a> [compute\_plane](#input\_compute\_plane) | Parameters of the compute plane | <pre>map(object({<br>    partition_data = object({<br>      priority              = number<br>      reserved_pods         = number<br>      max_pods              = number<br>      preemption_percentage = number<br>      parent_partition_ids  = list(string)<br>      pod_configuration     = any<br>    })<br>    replicas                         = number<br>    termination_grace_period_seconds = number<br>    image_pull_secrets               = string<br>    node_selector                    = any<br>    annotations                      = any<br>    polling_agent = object({<br>      image             = string<br>      tag               = string<br>      image_pull_policy = string<br>      limits = object({<br>        cpu    = string<br>        memory = string<br>      })<br>      requests = object({<br>        cpu    = string<br>        memory = string<br>      })<br>    })<br>    worker = list(object({<br>      name              = string<br>      image             = string<br>      tag               = string<br>      image_pull_policy = string<br>      limits = object({<br>        cpu    = string<br>        memory = string<br>      })<br>      requests = object({<br>        cpu    = string<br>        memory = string<br>      })<br>    }))<br>    hpa = any<br>  }))</pre> | n/a | yes |
| <a name="input_control_plane"></a> [control\_plane](#input\_control\_plane) | Parameters of the control plane | <pre>object({<br>    name              = string<br>    service_type      = string<br>    replicas          = number<br>    image             = string<br>    tag               = string<br>    image_pull_policy = string<br>    port              = number<br>    limits = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    requests = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    image_pull_secrets = string<br>    node_selector      = any<br>    annotations        = any<br>    hpa                = any<br>    default_partition  = string<br>  })</pre> | n/a | yes |
| <a name="input_deployed_object_storage_secret_name"></a> [deployed\_object\_storage\_secret\_name](#input\_deployed\_object\_storage\_secret\_name) | the name of the deployed-object-storage secret | `string` | `"deployed-object-storage"` | no |
| <a name="input_deployed_queue_storage_secret_name"></a> [deployed\_queue\_storage\_secret\_name](#input\_deployed\_queue\_storage\_secret\_name) | the name of the deployed-queue-storage secret | `string` | `"deployed-queue-storage"` | no |
| <a name="input_deployed_table_storage_secret_name"></a> [deployed\_table\_storage\_secret\_name](#input\_deployed\_table\_storage\_secret\_name) | the name of the deployed-table-storage secret | `string` | `"deployed-table-storage"` | no |
| <a name="input_environment_description"></a> [environment\_description](#input\_environment\_description) | Description of the environment deployed | `any` | `null` | no |
| <a name="input_extra_conf"></a> [extra\_conf](#input\_extra\_conf) | Add extra configuration in the configmaps | <pre>object({<br>    compute = map(string)<br>    control = map(string)<br>    core    = map(string)<br>    log     = map(string)<br>    polling = map(string)<br>    worker  = map(string)<br>  })</pre> | <pre>{<br>  "compute": {},<br>  "control": {},<br>  "core": {},<br>  "log": {},<br>  "polling": {},<br>  "worker": {}<br>}</pre> | no |
| <a name="input_fluent_bit_secret_name"></a> [fluent\_bit\_secret\_name](#input\_fluent\_bit\_secret\_name) | the name of the fluent-bit secret | `string` | `"fluent-bit"` | no |
| <a name="input_grafana_secret_name"></a> [grafana\_secret\_name](#input\_grafana\_secret\_name) | the name of the grafana secret | `string` | `"grafana"` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Parameters of the ingress controller | <pre>object({<br>    name              = string<br>    service_type      = string<br>    replicas          = number<br>    image             = string<br>    tag               = string<br>    image_pull_policy = string<br>    http_port         = number<br>    grpc_port         = number<br>    limits = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    requests = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    image_pull_secrets    = string<br>    node_selector         = any<br>    annotations           = any<br>    tls                   = bool<br>    mtls                  = bool<br>    generate_client_cert  = bool<br>    custom_client_ca_file = string<br>  })</pre> | n/a | yes |
| <a name="input_job_partitions_in_database"></a> [job\_partitions\_in\_database](#input\_job\_partitions\_in\_database) | Job to insert partitions IDs in the database | <pre>object({<br>    name               = string<br>    image              = string<br>    tag                = string<br>    image_pull_policy  = string<br>    image_pull_secrets = string<br>    node_selector      = any<br>    annotations        = any<br>  })</pre> | n/a | yes |
| <a name="input_keda_chart_name"></a> [keda\_chart\_name](#input\_keda\_chart\_name) | Name of the Keda Helm chart | `string` | `"keda"` | no |
| <a name="input_logging_level"></a> [logging\_level](#input\_logging\_level) | Logging level in ArmoniK | `string` | n/a | yes |
| <a name="input_metrics_exporter_secret_name"></a> [metrics\_exporter\_secret\_name](#input\_metrics\_exporter\_secret\_name) | the name of the metrics exporter secret | `string` | `"metrics-exporter"` | no |
| <a name="input_metrics_server_chart_name"></a> [metrics\_server\_chart\_name](#input\_metrics\_server\_chart\_name) | Name of the metrics-server Helm chart | `string` | `"metrics-server"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK resources | `string` | n/a | yes |
| <a name="input_partition_metrics_exporter_secret_name"></a> [partition\_metrics\_exporter\_secret\_name](#input\_partition\_metrics\_exporter\_secret\_name) | the name of the partition metrics exporter secret | `string` | `"partition-metrics-exporter"` | no |
| <a name="input_prometheus_secret_name"></a> [prometheus\_secret\_name](#input\_prometheus\_secret\_name) | the name of the prometheus secret | `string` | `"prometheus"` | no |
| <a name="input_s3_secret_name"></a> [s3\_secret\_name](#input\_s3\_secret\_name) | the name of the S3 secret | `string` | `"s3"` | no |
| <a name="input_seq_secret_name"></a> [seq\_secret\_name](#input\_seq\_secret\_name) | the name of the seq secret | `string` | `"seq"` | no |
| <a name="input_shared_storage_secret_name"></a> [shared\_storage\_secret\_name](#input\_shared\_storage\_secret\_name) | the name of the shared-storage secret | `string` | `"shared-storage"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint_urls"></a> [endpoint\_urls](#output\_endpoint\_urls) | List of URL endpoints for: control-plane, Seq, Grafana and Admin GUI |
| <a name="output_object_storage_adapter"></a> [object\_storage\_adapter](#output\_object\_storage\_adapter) | Adapter used for the object storage |
| <a name="output_object_storage_adapter_check"></a> [object\_storage\_adapter\_check](#output\_object\_storage\_adapter\_check) | Check the adapter used for the object storage |
| <a name="output_queue_storage_adapter"></a> [queue\_storage\_adapter](#output\_queue\_storage\_adapter) | Adapter used for the quque storage |
| <a name="output_queue_storage_adapter_check"></a> [queue\_storage\_adapter\_check](#output\_queue\_storage\_adapter\_check) | Check the adapter used for the queue storage |
| <a name="output_table_storage_adapter"></a> [table\_storage\_adapter](#output\_table\_storage\_adapter) | Adapter used for the table storage |
| <a name="output_table_storage_adapter_check"></a> [table\_storage\_adapter\_check](#output\_table\_storage\_adapter\_check) | Check the adapter used for the table storage |
<!-- END_TF_DOCS -->
