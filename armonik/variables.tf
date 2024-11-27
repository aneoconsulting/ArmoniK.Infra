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
    name                  = string
    service_type          = string
    replicas              = number
    image                 = string
    tag                   = string
    image_pull_policy     = string
    http_port             = number
    grpc_port             = number
    limits                = optional(map(string))
    requests              = optional(map(string))
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

# Parameters of admin gui
variable "admin_gui" {
  description = "Parameters of the admin GUI"
  type = object({
    name               = string
    image              = string
    tag                = string
    port               = number
    limits             = optional(map(string))
    requests           = optional(map(string))
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
      entry   = string
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
