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
    annotations           = optional(map(string), {})
  })
  default = {}
}

# ──────────────────────────────────────────────
# Database cluster settings
# ──────────────────────────────────────────────
variable "cluster" {
  description = "Parameters for the Percona Server for MongoDB cluster"
  type = object({
    image         = optional(string, "percona/percona-server-mongodb")
    tag           = optional(string)
    database_name = optional(string, "database")
    replicas      = optional(number, 1)
    node_selector = optional(map(string), {})
    annotations   = optional(map(string), {})
  })
  default = {}
}

variable "tls" {
  description = <<-EOT
    TLS configuration for the Percona MongoDB cluster.

    self_managed         – When true (default), Terraform generates the CA and server
                           certificates using the `tls` provider and pre-creates
                           the ssl / ssl-internal Kubernetes secrets. The
                           Percona operator then uses those secrets directly
                           without invoking cert-manager.
                           When false, the operator delegates
                           certificate generation to cert-manager; cert-manager
                           must therefore be installed in the cluster.

    validity_period_hours – Lifetime of the generated certificates in hours.
                            Only relevant when self_managed = true.
                            Defaults to 8760h (1 year).
  EOT
  type = object({
    self_managed          = optional(bool, true)
    validity_period_hours = optional(number, 8760)
  })
  default = {}
}
variable "resources" {
  description = "Resource requests and limits per component"
  type = object({
    shards = optional(object({
      limits   = optional(map(string))
      requests = optional(map(string))
    }), {})
    configsvr = optional(object({
      limits   = optional(map(string))
      requests = optional(map(string))
    }), {})
    mongos = optional(object({
      limits   = optional(map(string))
      requests = optional(map(string))
    }), {})
  })
  default = {}
}

variable "sharding" {
  description = "Sharding configuration. Set to null to disable sharding."
  type = object({
    shards_quantity = optional(number, 1)
    configsvr = optional(object({
      replicas      = optional(number, 1)
      node_selector = optional(map(string), {})
    }), {})
    mongos = optional(object({
      replicas      = optional(number, 1)
      node_selector = optional(map(string), {})
    }), {})
  })
  default = null
}

variable "persistence" {
  description = "Persistence parameters for MongoDB pods"
  type = object({
    shards = optional(object({
      mount_options       = optional(string)
      storage_size        = optional(string, "8Gi")
      storage_class_name  = optional(string) # Use existing StorageClass
      storage_provisioner = optional(string) # Or create one
      reclaim_policy      = optional(string, "Delete")
      volume_binding_mode = optional(string, "WaitForFirstConsumer")
      access_modes        = optional(list(string), ["ReadWriteOnce"])
      parameters          = optional(map(string), {})
    }), {})

    configsvr = optional(object({
      mount_options       = optional(string)
      storage_size        = optional(string, "3Gi")
      storage_class_name  = optional(string)
      storage_provisioner = optional(string)
      reclaim_policy      = optional(string, "Delete")
      volume_binding_mode = optional(string, "WaitForFirstConsumer")
      access_modes        = optional(list(string), ["ReadWriteOnce"])
      parameters          = optional(map(string), {})
    }), {})
  })
  default = null
}

# ──────────────────────────────────────────────
# General helm settings
# ──────────────────────────────────────────────

variable "timeout" {
  description = "Timeout in seconds for the helm release creation"
  type        = number
  default     = 600
}
