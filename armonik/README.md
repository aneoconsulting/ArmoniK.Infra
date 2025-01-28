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
| <a name="module_admin_gui_endpoint"></a> [admin\_gui\_endpoint](#module\_admin\_gui\_endpoint) | ../utils/service-ip | n/a |
| <a name="module_compute_aggregation"></a> [compute\_aggregation](#module\_compute\_aggregation) | ../utils/aggregator | n/a |
| <a name="module_control_plane_aggregation"></a> [control\_plane\_aggregation](#module\_control\_plane\_aggregation) | ../utils/aggregator | n/a |
| <a name="module_control_plane_endpoint"></a> [control\_plane\_endpoint](#module\_control\_plane\_endpoint) | ../utils/service-ip | n/a |
| <a name="module_core_aggregation"></a> [core\_aggregation](#module\_core\_aggregation) | ../utils/aggregator | n/a |
| <a name="module_ingress_endpoint"></a> [ingress\_endpoint](#module\_ingress\_endpoint) | ../utils/service-ip | n/a |
| <a name="module_job_aggregation"></a> [job\_aggregation](#module\_job\_aggregation) | ../utils/aggregator | n/a |
| <a name="module_log_aggregation"></a> [log\_aggregation](#module\_log\_aggregation) | ../utils/aggregator | n/a |
| <a name="module_metrics_aggregation"></a> [metrics\_aggregation](#module\_metrics\_aggregation) | ../utils/aggregator | n/a |
| <a name="module_polling_agent_aggregation"></a> [polling\_agent\_aggregation](#module\_polling\_agent\_aggregation) | ../utils/aggregator | n/a |
| <a name="module_polling_all_aggregation"></a> [polling\_all\_aggregation](#module\_polling\_all\_aggregation) | ../utils/aggregator | n/a |
| <a name="module_worker_aggregation"></a> [worker\_aggregation](#module\_worker\_aggregation) | ../utils/aggregator | n/a |
| <a name="module_worker_all_aggregation"></a> [worker\_all\_aggregation](#module\_worker\_all\_aggregation) | ../utils/aggregator | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.keda_hpa_compute_plane](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.keda_hpa_control_plane](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_config_map.authmongo](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.static](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_cron_job_v1.partitions_in_database](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cron_job_v1) | resource |
| [kubernetes_deployment.admin_gui](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.compute_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.metrics_exporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.pod_deletion_cost](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_job.authentication_in_database](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/job) | resource |
| [kubernetes_job.partitions_in_database](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/job) | resource |
| [kubernetes_role.pod_deletion_cost](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) | resource |
| [kubernetes_role_binding.pod_deletion_cost](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [kubernetes_secret.ingress_certificate](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.ingress_client_certificate](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.ingress_client_certificate_authority](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service.admin_gui](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service.control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service.ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service_account.pod_deletion_cost](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
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
| [tls_certificate.certificate_data](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_gui"></a> [admin\_gui](#input\_admin\_gui) | Parameters of the admin GUI | <pre>object({<br>    name               = string<br>    image              = string<br>    tag                = string<br>    port               = number<br>    limits             = optional(map(string))<br>    requests           = optional(map(string))<br>    service_type       = string<br>    replicas           = number<br>    image_pull_policy  = string<br>    image_pull_secrets = string<br>    node_selector      = any<br>  })</pre> | `null` | no |
| <a name="input_authentication"></a> [authentication](#input\_authentication) | Authentication behavior | <pre>object({<br>    name                    = string<br>    image                   = string<br>    tag                     = string<br>    image_pull_policy       = string<br>    image_pull_secrets      = string<br>    node_selector           = any<br>    authentication_datafile = string<br>    require_authentication  = bool<br>    require_authorization   = bool<br>  })</pre> | n/a | yes |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Name for chart | `string` | `"keda-hpa"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Version for chart | `string` | `"0.1.0"` | no |
| <a name="input_charts_repository"></a> [charts\_repository](#input\_charts\_repository) | Path to the charts repository | `string` | `"../charts"` | no |
| <a name="input_compute_plane"></a> [compute\_plane](#input\_compute\_plane) | Parameters of the compute plane | <pre>map(object({<br>    partition_data = object({<br>      priority              = number<br>      reserved_pods         = number<br>      max_pods              = number<br>      preemption_percentage = number<br>      parent_partition_ids  = list(string)<br>      pod_configuration     = any<br>    })<br>    replicas                         = number<br>    termination_grace_period_seconds = number<br>    image_pull_secrets               = string<br>    node_selector                    = any<br>    annotations                      = any<br>    service_account_name             = string<br>    socket_type                      = optional(string)<br>    polling_agent = object({<br>      image             = string<br>      tag               = string<br>      image_pull_policy = string<br>      limits            = optional(map(string))<br>      requests          = optional(map(string))<br>      conf              = optional(any, {})<br>    })<br>    worker = list(object({<br>      name              = string<br>      image             = string<br>      tag               = string<br>      image_pull_policy = string<br>      limits            = optional(map(string))<br>      requests          = optional(map(string))<br>      conf              = optional(any, {})<br>    }))<br>    cache_config = object({<br>      memory     = bool<br>      size_limit = string # if larger than supported, the max value for the node will be used instead<br>    })<br>    readiness_probe = optional(bool, false)<br>    hpa             = any<br>  }))</pre> | n/a | yes |
| <a name="input_configurations"></a> [configurations](#input\_configurations) | Extra configurations for the various components | <pre>object({<br>    core    = optional(any, [])<br>    control = optional(any, [])<br>    compute = optional(any, [])<br>    worker  = optional(any, [])<br>    polling = optional(any, [])<br>    log     = optional(any, [])<br>    metrics = optional(any, [])<br>    jobs    = optional(any, [])<br>  })</pre> | n/a | yes |
| <a name="input_control_plane"></a> [control\_plane](#input\_control\_plane) | Parameters of the control plane | <pre>object({<br>    name                 = string<br>    service_type         = string<br>    replicas             = number<br>    image                = string<br>    tag                  = string<br>    image_pull_policy    = string<br>    port                 = number<br>    limits               = optional(map(string))<br>    requests             = optional(map(string))<br>    image_pull_secrets   = string<br>    node_selector        = any<br>    annotations          = any<br>    hpa                  = any<br>    default_partition    = string<br>    service_account_name = string<br>  })</pre> | n/a | yes |
| <a name="input_environment_description"></a> [environment\_description](#input\_environment\_description) | Description of the environment deployed | `any` | `null` | no |
| <a name="input_fluent_bit"></a> [fluent\_bit](#input\_fluent\_bit) | the fluent-bit module output | <pre>object({<br>    configmaps = object({<br>      envvars = string<br>      config  = string<br>    })<br>    container_name = string<br>    image          = string<br>    is_daemonset   = bool<br>    tag            = string<br>  })</pre> | `null` | no |
| <a name="input_grafana"></a> [grafana](#input\_grafana) | the grafana module output | <pre>object({<br>    host = string<br>    port = string<br>    url  = string<br>  })</pre> | `null` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Parameters of the ingress controller | <pre>object({<br>    name                  = string<br>    service_type          = string<br>    replicas              = number<br>    image                 = string<br>    tag                   = string<br>    image_pull_policy     = string<br>    http_port             = number<br>    grpc_port             = number<br>    limits                = optional(map(string))<br>    requests              = optional(map(string))<br>    image_pull_secrets    = string<br>    node_selector         = any<br>    annotations           = any<br>    tls                   = bool<br>    mtls                  = bool<br>    generate_client_cert  = bool<br>    custom_client_ca_file = string<br>    langs                 = optional(set(string), ["en"])<br>  })</pre> | n/a | yes |
| <a name="input_job_partitions_in_database"></a> [job\_partitions\_in\_database](#input\_job\_partitions\_in\_database) | Job to insert partitions IDs in the database | <pre>object({<br>    name               = string<br>    image              = string<br>    tag                = string<br>    image_pull_policy  = string<br>    image_pull_secrets = string<br>    node_selector      = any<br>    annotations        = any<br>  })</pre> | n/a | yes |
| <a name="input_keda_chart_name"></a> [keda\_chart\_name](#input\_keda\_chart\_name) | Name of the Keda Helm chart | `string` | `"keda"` | no |
| <a name="input_logging_level"></a> [logging\_level](#input\_logging\_level) | Logging level in ArmoniK | `string` | n/a | yes |
| <a name="input_metrics"></a> [metrics](#input\_metrics) | the metrics exporter module output | <pre>object({<br>    host      = string<br>    name      = string<br>    namespace = string<br>    port      = string<br>    url       = string<br>  })</pre> | `null` | no |
| <a name="input_metrics_exporter"></a> [metrics\_exporter](#input\_metrics\_exporter) | Parameters of Metrics exporter | <pre>object({<br>    image              = string<br>    tag                = string<br>    image_pull_policy  = optional(string, "IfNotPresent")<br>    image_pull_secrets = optional(string, "")<br>    node_selector      = optional(any, {})<br>    name               = optional(string, "metrics-exporter")<br>    label_app          = optional(string, "armonik")<br>    label_service      = optional(string, "metrics-exporter")<br>    port_name          = optional(string, "metrics")<br>    port               = optional(number, 9419)<br>    target_port        = optional(number, 1080)<br>  })</pre> | n/a | yes |
| <a name="input_metrics_server_chart_name"></a> [metrics\_server\_chart\_name](#input\_metrics\_server\_chart\_name) | Name of the metrics-server Helm chart | `string` | `"metrics-server"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK resources | `string` | n/a | yes |
| <a name="input_pod_deletion_cost"></a> [pod\_deletion\_cost](#input\_pod\_deletion\_cost) | value | <pre>object({<br>    image               = string<br>    tag                 = string<br>    image_pull_policy   = optional(string, "IfNotPresent")<br>    image_pull_secrets  = optional(string, "")<br>    node_selector       = optional(any, {})<br>    annotations         = optional(any, {})<br>    name                = optional(string, "pdc-update")<br>    label_app           = optional(string, "armonik")<br>    prometheus_url      = optional(string)<br>    metrics_name        = optional(string)<br>    period              = optional(number)<br>    ignore_younger_than = optional(number)<br>    concurrency         = optional(number)<br>    granularity         = optional(number)<br>    extra_conf          = optional(map(string), {})<br>    limits              = optional(map(string))<br>    requests            = optional(map(string))<br>  })</pre> | `null` | no |
| <a name="input_prometheus"></a> [prometheus](#input\_prometheus) | the prometheus module output | <pre>object({<br>    host = string<br>    port = string<br>    url  = string<br>  })</pre> | `null` | no |
| <a name="input_seq"></a> [seq](#input\_seq) | the seq module output | <pre>object({<br>    host    = string<br>    port    = string<br>    url     = string<br>    web_url = string<br>  })</pre> | `null` | no |
| <a name="input_shared_storage_settings"></a> [shared\_storage\_settings](#input\_shared\_storage\_settings) | the shared-storage configuration information | <pre>object({<br>    file_storage_type     = optional(string)<br>    service_url           = optional(string)<br>    console_url           = optional(string)<br>    access_key_id         = optional(string)<br>    secret_access_key     = optional(string)<br>    name                  = optional(string)<br>    must_force_path_style = optional(string)<br>    host_path             = optional(string)<br>    file_server_ip        = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_static"></a> [static](#input\_static) | json files to be served statically by the ingress | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint_urls"></a> [endpoint\_urls](#output\_endpoint\_urls) | List of URL endpoints for: control-plane, Seq, Grafana and Admin GUI |
<!-- END_TF_DOCS -->
