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
    name              = string
    service_type      = string
    replicas          = number
    image             = string
    tag               = string
    image_pull_policy = string
    http_port         = number
    grpc_port         = number
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
    image_pull_secrets    = string
    node_selector         = any
    annotations           = any
    tls                   = bool
    mtls                  = bool
    generate_client_cert  = bool
    custom_client_ca_file = string
    langs                 = optional(set(string), ["en"])
  })
  validation {
    error_message = "Ingress mTLS requires TLS to be enabled."
    condition     = var.ingress != null ? !var.ingress.mtls || var.ingress.tls : true
  }
  validation {
    error_message = "Without TLS, http_port and grpc_port must be different."
    condition     = var.ingress != null ? var.ingress.http_port != var.ingress.grpc_port || var.ingress.tls : true
  }
  validation {
    error_message = "Client certificate generation requires mTLS to be enabled."
    condition     = var.ingress != null ? !var.ingress.generate_client_cert || var.ingress.mtls : true
  }
  validation {
    error_message = "Cannot generate client certificates if the client CA is custom."
    condition     = var.ingress != null ? !var.ingress.mtls || var.ingress.custom_client_ca_file == "" || !var.ingress.generate_client_cert : true
  }
  validation {
    error_message = "English must be supported."
    condition     = contains(var.ingress.langs, "en")
  }
}

# Extra configuration
variable "extra_conf" {
  description = "Add extra configuration in the configmaps"
  type = object({
    compute = map(string)
    control = map(string)
    core    = map(string)
    log     = map(string)
    metrics = map(string)
    polling = map(string)
    worker  = map(string)
  })
  default = {
    compute = {}
    control = {}
    core    = {}
    log     = {}
    metrics = {}
    polling = {}
    worker  = {}
  }
}

# Extra configuration
variable "jobs_in_database_extra_conf" {
  description = "Add extra configuration in the configmaps for jobs connecting to database"
  type        = map(string)
  default     = {}
}

# Job to insert partitions in the database
variable "job_partitions_in_database" {
  description = "Job to insert partitions IDs in the database"
  type = object({
    name               = string
    image              = string
    tag                = string
    image_pull_policy  = string
    image_pull_secrets = string
    node_selector      = any
    annotations        = any
  })
}

# Parameters of control plane
variable "control_plane" {
  description = "Parameters of the control plane"
  type = object({
    name              = string
    service_type      = string
    replicas          = number
    image             = string
    tag               = string
    image_pull_policy = string
    port              = number
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
    image_pull_secrets   = string
    node_selector        = any
    annotations          = any
    hpa                  = any
    default_partition    = string
    service_account_name = string
    #conf
    conf = any
  })
}

# Parameters of admin gui
variable "admin_gui" {
  description = "Parameters of the admin GUI"
  type = object({
    name  = string
    image = string
    tag   = string
    port  = number
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
    service_type       = string
    replicas           = number
    image_pull_policy  = string
    image_pull_secrets = string
    node_selector      = any
  })
  default = null
}

# Deprecated, must be removed in a future version
# Parameters of admin gui v0.8 (previously called old admin gui)
variable "admin_0_8_gui" {
  description = "Parameters of the admin GUI v0.8"
  type = object({
    api = object({
      name  = string
      image = string
      tag   = string
      port  = number
      limits = object({
        cpu    = string
        memory = string
      })
      requests = object({
        cpu    = string
        memory = string
      })
    })
    app = object({
      name  = string
      image = string
      tag   = string
      port  = number
      limits = object({
        cpu    = string
        memory = string
      })
      requests = object({
        cpu    = string
        memory = string
      })
    })
    service_type       = string
    replicas           = number
    image_pull_policy  = string
    image_pull_secrets = string
    node_selector      = any
  })
  default = null
}

# Deprecated, must be removed in a future version
# Parameters of admin gui v0.9
variable "admin_0_9_gui" {
  description = "Parameters of the admin GUI v0.9"
  type = object({
    name  = string
    image = string
    tag   = string
    port  = number
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
    service_type       = string
    replicas           = number
    image_pull_policy  = string
    image_pull_secrets = string
    node_selector      = any
  })
  default = null
}

# Parameters of the compute plane
variable "compute_plane" {
  description = "Parameters of the compute plane"
  type = map(object({
    partition_data = object({
      priority              = number
      reserved_pods         = number
      max_pods              = number
      preemption_percentage = number
      parent_partition_ids  = list(string)
      pod_configuration     = any
    })
    replicas                         = number
    termination_grace_period_seconds = number
    image_pull_secrets               = string
    node_selector                    = any
    annotations                      = any
    service_account_name             = string
    polling_agent = object({
      image             = string
      tag               = string
      image_pull_policy = string
      limits = object({
        cpu    = string
        memory = string
      })
      requests = object({
        cpu    = string
        memory = string
      })
      #conf
      conf = any
    })
    worker = list(object({
      name              = string
      image             = string
      tag               = string
      image_pull_policy = string
      limits = object({
        cpu    = string
        memory = string
      })
      requests = object({
        cpu    = string
        memory = string
      })
      #conf
      conf = any
    }))
    cache_config = object({
      memory     = bool
      size_limit = string # if larger than supported, the max value for the node will be used instead
    })
    readiness_probe = optional(bool, false)
    hpa             = any
  }))
}

# Authentication behavior
variable "authentication" {
  description = "Authentication behavior"
  type = object({
    name                    = string
    image                   = string
    tag                     = string
    image_pull_policy       = string
    image_pull_secrets      = string
    node_selector           = any
    authentication_datafile = string
    require_authentication  = bool
    require_authorization   = bool
  })
  validation {
    error_message = "Authorization requires authentication to be activated."
    condition     = var.authentication == null || var.authentication.require_authentication || !var.authentication.require_authorization
  }
  validation {
    error_message = "File specified in authentication.authentication_datafile must be a valid json file if the field is not empty."
    condition     = var.authentication == null || !var.authentication.require_authentication || var.authentication.authentication_datafile == "" || try(fileexists(var.authentication.authentication_datafile), false) && can(jsondecode(file(var.authentication.authentication_datafile)))
  }
}

# The output of modules.
variable "fluent_bit_output" {
  description = "the fluent-bit module output"
  type        = any
  default     = {}
}

variable "grafana_output" {
  description = "the grafana module output"
  type        = any
  default     = {}
}

variable "prometheus_output" {
  description = "the prometheus module output"
  type        = any
  default     = {}
}

variable "metrics_exporter_output" {
  description = "the metrics exporter module output"
  type        = any
  default     = {}
}

# variable "partition_metrics_exporter_output" {
#   description = "the partition metrics exporter module output"
#   type        = any
#   default     = {}
# }

variable "seq_output" {
  description = "the seq module output"
  type        = any
  default     = {}
}

variable "shared_storage_settings" {
  description = "the shared-storage configuration information"
  type        = any
  default     = {}
}

# variable "deployed_object_storage_secret_name" {
#   description = "the name of the deployed-object-storage secret"
#   type        = string
#   default     = "deployed-object-storage"
# }

# variable "deployed_table_storage_secret_name" {
#   description = "the name of the deployed-table-storage secret"
#   type        = string
#   default     = "deployed-table-storage"
# }

# variable "deployed_queue_storage_secret_name" {
#   description = "the name of the deployed-queue-storage secret"
#   type        = string
#   default     = "deployed-queue-storage"
# }

# variable "s3_secret_name" {
#   description = "the name of the S3 secret"
#   type        = string
#   default     = "s3"
# }

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

# # nfs_parameters
# variable "pvc_name" {
#   description = "Name for the pvc to be used"
#   type        = string
#   default     = "nfsvolume"
# }

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
    #conf
    conf = any
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

    limits = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    requests = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
  })
  default = null
}

# Extra configuration
variable "others_conf" {
  description = "Variable"
  type = object({
    database = any
  })
  default = {
    database = {}
  }
}
