# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Version helm chart
variable "chart_version" {
  type        = string
  description = "Version for chart"
  default     = "0.1.0" # Enter your desired version of helm chart here
}

# Name Helm chart
variable "chart_name" {
  type        = string
  description = "Name for chart"
  default     = "keda-hpa" # Enter your desired name of Helm chart here
}

# Path helm chart
variable "charts_repository" {
  type        = string
  description = "Path to the charts repository"
  default     = "../charts" # Enter your desired relative path here
}

# Logging level
variable "logging_level" {
  description = "Logging level in ArmoniK"
  type        = string
}

# Parameters of ingress
variable "ingress" {
  description = "Parameters of the ingress controller"
  type = object({
    name                   = optional(string, "ingress")
    service_type           = optional(string, "LoadBalancer")
    replicas               = optional(number, 1)
    image                  = optional(string, "nginxinc/nginx-unprivileged")
    tag                    = optional(string)
    image_pull_policy      = optional(string, "IfNotPresent")
    http_port              = optional(number, 5000)
    grpc_port              = optional(number, 5001)
    limits                 = optional(map(string))
    requests               = optional(map(string))
    image_pull_secrets     = optional(string, "")
    node_selector          = optional(map(string))
    annotations            = optional(map(string))
    tls                    = optional(bool, false)
    mtls                   = optional(bool, false)
    generate_client_cert   = optional(bool, false)
    custom_client_ca_file  = optional(string, "")
    langs                  = optional(set(string), ["en"])
    cors_allowed_host      = optional(string, "*")
    cors_allowed_headers   = optional(set(string), []) # Will be added to the default cors headers.
    cors_allowed_methods   = optional(set(string), ["GET", "POST", "OPTIONS"])
    cors_preflight_max_age = optional(number, 1728000)
  })
  validation {
    error_message = "Ingress mTLS requires TLS to be enabled."
    condition     = !try(var.ingress.mtls, false) || var.ingress.tls
  }
  validation {
    error_message = "Without TLS, http_port and grpc_port must be different."
    condition     = !(try(var.ingress.tls, true)) ? try((var.ingress.http_port != var.ingress.grpc_port), true) : true
  }
  validation {
    error_message = "Client certificate generation requires mTLS to be enabled."
    condition     = try(var.ingress.generate_client_cert, false) ? try(var.ingress.mtls, true) : true
  }
  validation {
    error_message = "English must be supported."
    condition     = contains(try(var.ingress.langs, ["en"]), "en")
  }
  validation {
    error_message = "Length of 'var.ingress.name' must not exceed 10 characters"
    condition     = length(try(var.ingress.name, "")) > 10 ? false : true
  }
}

# Job to insert partitions in the database
variable "job_partitions_in_database" {
  description = "LEGACY: Job to insert partitions IDs in the database"
  type = object({
    name               = string
    image              = string
    tag                = string
    image_pull_policy  = string
    image_pull_secrets = string
    node_selector      = any
    annotations        = any
  })

  default = null
}

# Parameters of control plane
variable "control_plane" {
  description = "Parameters of the control plane"
  type = object({
    name                 = string
    service_type         = string
    replicas             = number
    image                = string
    tag                  = string
    image_pull_policy    = string
    port                 = number
    limits               = optional(map(string))
    requests             = optional(map(string))
    image_pull_secrets   = string
    node_selector        = any
    annotations          = any
    hpa                  = any
    default_partition    = string
    service_account_name = string
  })
}

variable "init" {
  description = "Parameters of the init job"
  type = object({
    name               = optional(string, "init")
    image              = string
    tag                = string
    image_pull_policy  = string
    image_pull_secrets = string
    node_selector      = map(string)
    annotations        = map(string)
    populate = optional(object({
      partitions     = optional(bool, true)
      authentication = optional(bool, true)
    }), {})
  })

  default = null
}

# Parameters of admin gui
variable "admin_gui" {
  description = "Parameters of the admin GUI"
  type = object({
    name  = optional(string, "admin-app")
    image = optional(string, "dockerhubaneo/armonik_admin_app")
    tag   = string
    port  = optional(number, 1080)
    limits = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    requests = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    service_type       = optional(string, "ClusterIP")
    replicas           = optional(number, 1)
    image_pull_policy  = optional(string, "IfNotPresent")
    image_pull_secrets = optional(string, "")
    node_selector      = optional(map(string), {})
  })
  default = null
}

# Parameters of the compute plane
variable "compute_plane" {
  description = "Parameters of the compute plane"
  type = map(object({
    partition_data = object({
      priority              = optional(number, 1)
      reserved_pods         = optional(number, 0)
      max_pods              = optional(number, 1)
      preemption_percentage = optional(number, 0)
      parent_partition_ids  = optional(set(string), [])
      pod_configuration     = optional(map(string), {})
    })
    replicas                         = number
    termination_grace_period_seconds = number
    image_pull_secrets               = string
    node_selector                    = any
    annotations                      = any
    service_account_name             = string
    socket_type                      = optional(string, "unixdomainsocket")
    security = optional(object({
      user = optional(number, 5000) # keep default user if set to -1
    }), {})
    polling_agent = object({
      image             = string
      tag               = string
      image_pull_policy = string
      limits            = optional(map(string))
      requests          = optional(map(string))
      conf              = optional(any, {})
    })
    worker = list(object({
      name              = string
      image             = string
      tag               = string
      image_pull_policy = string
      limits            = optional(map(string))
      requests          = optional(map(string))
      conf              = optional(any, {})
    }))
    cache_config = object({
      memory     = bool
      size_limit = string # if larger than supported, the max value for the node will be used instead
    })
    node_cache = optional(object({
      path      = optional(string)
      threshold = optional(number, 0)
    }))
    readiness_probe = optional(bool, false)
    hpa             = any
  }))
}

# Authentication behavior
variable "authentication" {
  description = "Authentication behavior"
  type = object({
    name                    = optional(string)
    image                   = optional(string)
    tag                     = optional(string)
    image_pull_policy       = optional(string)
    image_pull_secrets      = optional(string)
    node_selector           = optional(any)
    authentication_datafile = optional(string)
    require_authentication  = bool
    require_authorization   = bool
    trusted_common_names    = optional(set(string), [])
  })
  validation {
    error_message = "Authorization requires authentication to be activated."
    condition     = var.authentication == null || var.authentication.require_authentication || !var.authentication.require_authorization
  }
  validation {
    error_message = "File specified in authentication.authentication_datafile must be a valid json file if the field is not empty."
    condition     = !can(coalesce(var.authentication.authentication_datafile)) || !var.authentication.require_authentication || try(fileexists(var.authentication.authentication_datafile), false) && can(jsondecode(file(var.authentication.authentication_datafile)))
  }
  # validation {
  #   error_message = "Authentication or authorization requires mTLS"
  #   condition     = var.authentication == null || !var.authentication.require_authentication || length(var.authentication.trusted_common_names) > 0
  # }
}

# The output of modules.
variable "fluent_bit" {
  description = "the fluent-bit module output"
  type = object({
    configmaps = object({
      envvars = string
      config  = string
    })
    container_name = string
    image          = string
    is_daemonset   = bool
    tag            = string

    windows_configmaps = object({
      envvars = string
      config  = string
    })
    windows_container_name = string
    windows_image          = string
    windows_is_daemonset   = bool
    windows_tag            = string
  })
  default = null
}

variable "grafana" {
  description = "the grafana module output"
  type = object({
    host = string
    port = string
    url  = string
  })
  default = null
}


variable "prometheus" {
  description = "the prometheus module output"
  type = object({
    host = string
    port = string
    url  = string
  })
  default = null
}

variable "metrics" {
  description = "the metrics exporter module output"
  type = object({
    host      = string
    name      = string
    namespace = string
    port      = string
    url       = string
  })
  default = null
}

variable "seq" {
  description = "the seq module output"
  type = object({
    host    = string
    port    = string
    url     = string
    web_url = string
  })
  default = null
}

variable "shared_storage_settings" {
  description = "the shared-storage configuration information"
  type = object({
    file_storage_type     = optional(string)
    service_url           = optional(string)
    console_url           = optional(string)
    access_key_id         = optional(string)
    secret_access_key     = optional(string)
    name                  = optional(string)
    must_force_path_style = optional(string)
    host_path             = optional(string)
    file_server_ip        = optional(string)
  })
  default = null
}

variable "keda_chart_name" {
  description = "Name of the Keda Helm chart"
  type        = string
  default     = "keda"
}

variable "metrics_server_chart_name" {
  description = "Name of the metrics-server Helm chart"
  type        = string
  default     = "metrics-server"
}

variable "environment_description" {
  description = "Description of the environment deployed"
  type        = any
  default     = null
}

variable "static" {
  description = "json files to be served statically by the ingress"
  type        = any
  default     = {}
}

# metrics information
variable "metrics_exporter" {
  description = "Parameters of Metrics exporter"
  type = object({
    image              = string
    tag                = string
    image_pull_policy  = optional(string, "IfNotPresent")
    image_pull_secrets = optional(string, "")
    node_selector      = optional(any, {})
    name               = optional(string, "metrics-exporter")
    label_app          = optional(string, "armonik")
    label_service      = optional(string, "metrics-exporter")
    port_name          = optional(string, "metrics")
    port               = optional(number, 9419)
    target_port        = optional(number, 1080)
  })
}

variable "pod_deletion_cost" {
  description = "value"
  type = object({
    image               = string
    tag                 = string
    image_pull_policy   = optional(string, "IfNotPresent")
    image_pull_secrets  = optional(string, "")
    node_selector       = optional(any, {})
    annotations         = optional(any, {})
    name                = optional(string, "pdc-update")
    label_app           = optional(string, "armonik")
    prometheus_url      = optional(string)
    metrics_name        = optional(string)
    period              = optional(number)
    ignore_younger_than = optional(number)
    concurrency         = optional(number)
    granularity         = optional(number)
    extra_conf          = optional(map(string), {})
    limits              = optional(map(string))
    requests            = optional(map(string))
  })
  default = null
}

variable "configurations" {
  description = "Extra configurations for the various components"
  type = object({
    core    = optional(any, [])
    control = optional(any, [])
    compute = optional(any, [])
    worker  = optional(any, [])
    polling = optional(any, [])
    log     = optional(any, [])
    metrics = optional(any, [])
    jobs    = optional(any, [])
  })
}

# variable "clusters" {
#   type = map(object({
#     endpoint                = optional(string)
#     cert_pem                = optional(string)
#     key_pem                 = optional(string)
#     ca_cert                 = optional(string)
#     allow_unsafe_connection = optional(bool, false)
#     override_target_name    = optional(string)
#     pool_size               = optional(number)
#     requests_per_connection = optional(number)
#     multiplex               = optional(bool, false)
#     fallback                = optional(bool, false)
#     forward_headers         = optional(list(string))
#     grafana_url             = optional(string)
#     seq_url                 = optional(string)
#     s3_urls = optional(object({
#       service = string
#       console = string
#     }))
#   }))
#   default = null
#   validation {
#     error_message = "var.clusters can only be used if load balancing is active (var.load_balancer not null)"
#     condition     = var.clusters != null ? var.load_balancer != null : true
#   }
# }

# variable "default_cluster" {
#   type    = string
#   default = null
#   validation {
#     error_message = "var.default_cluster is irrelevant if no cluster is provided (i.e. var.clusters is null)"
#     condition = can(try(coalesce(var.default_cluster))) ? can(try(coalescelist(keys(var.clusters)))) : true
#   }
#   validation {
#     error_message = "var.default_cluster must correspond to a key of var.clusters"
#     condition     = can(try(coalesce(var.default_cluster))) ? contains(coalescelist(keys(var.clusters), [""]), var.default_cluster) : true
#   }
#   validation {
#     error_message = "var.default_cluster is irrelevant if load balancing is not enforced (i.e. if var.load_balancer is null)"
#     condition     = can(try(coalesce(var.default_cluster))) ? var.load_balancer != null : true
#   }
# }

variable "load_balancer" {
  description = "Parameters of the Load Balancer deployment"
  type = object({
    image              = optional(string, "dockerhubaneo/armonik_load_balancer")
    tag                = optional(string)
    image_pull_policy  = optional(string, "IfNotPresent")
    limits             = optional(map(string))
    requests           = optional(map(string))
    image_pull_secrets = optional(string, "")
    replicas           = optional(number, 1)
    node_selector      = optional(map(string), {})
    annotations        = optional(map(string), {})
    service = optional(object({
      type        = optional(string, "HeadLess")
      annotations = optional(map(string), {})
    }))
    labels = optional(map(string), {
      app     = "armonik",
      service = "load-balancer"
    })
    conf = optional(object({
      listen_ip             = optional(string)
      listen_port           = optional(number, 8081)
      refresh_delay_seconds = optional(number)
      sqlite_db_path        = optional(string)
      session_cache_size    = optional(number)
      result_cache_size     = optional(number)
      task_cache_size       = optional(number)
    }), {})
    extra_env = optional(map(string))
  })
  default = null
}
