variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
  default     = "default"
}

variable "name" {
  description = "Name used for the helm chart release and the associated resources"
  type        = string
  default     = "percona-mongodb"
  validation {
    condition     = length(var.name) < 54
    error_message = "Helm release name must be shorter than 54 characters"
  }
}

# ──────────────────────────────────────────────
# Operator settings 
# ──────────────────────────────────────────────
variable "operator" {
  description = "Parameters for the Percona PSMDB Operator deployment"
  type = object({
    helm_chart_repository = optional(string, "https://percona.github.io/percona-helm-charts/")
    helm_chart_name       = optional(string, "psmdb-operator")
    helm_chart_version    = optional(string)
    image                 = optional(string, "percona/percona-server-mongodb-operator")
    tag                   = optional(string)
    node_selector         = optional(map(string), {})
  })
  default = {}
}

# ──────────────────────────────────────────────
# Database cluster settings
# ──────────────────────────────────────────────
variable "cluster" {
  description = "Parameters for the Percona Server for MongoDB cluster"
  type = object({
    helm_chart_repository = optional(string, "https://percona.github.io/percona-helm-charts/")
    helm_chart_name       = optional(string, "psmdb-db")
    helm_chart_version    = optional(string)
    image                 = optional(string, "percona/percona-server-mongodb")
    tag                   = optional(string)
    database_name         = optional(string, "database")
    replicas              = optional(number, 1)
    node_selector         = optional(map(string), {})
  })
  default = {}
}

# TODO: a lot of missing options

variable "sharding" {
  description = "Sharding configuration. Set to null to disable sharding."
  type = object({
    enabled = optional(bool, false)
    configsvr = optional(object({
      replicas = optional(number, 1)
    }), {})
    mongos = optional(object({
      replicas = optional(number, 1)
    }), {})
  })
  default = null
}

# TODO: add more options to this too
variable "persistence" {
  description = "Persistence parameters for MongoDB pods"
  type = object({
    storage_size = optional(string, "8Gi")
  })
  default = {}
}

# ──────────────────────────────────────────────
# General helm settings
# ──────────────────────────────────────────────

variable "timeout" {
  description = "Timeout in seconds for the helm release creation"
  type        = number
  default     = 600
}
