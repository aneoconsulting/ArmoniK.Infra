variable "name" {
  description = "The ID of the instance or a fully qualified identifier for the instance."
  type        = string
}

variable "authorized_network" {
  description = "The full name of the Google Compute Engine network to which the instance is connected. If left unspecified, the default network will be used."
  type        = string
  default     = null
}

variable "tier" {
  description = "The service tier of the instance."
  type        = string
  default     = "STANDARD_HA"
}

variable "memory_size_gb" {
  description = "Redis memory size in GiB."
  type        = number
  default     = 1
}

variable "replica_count" {
  description = "The number of replicas."
  type        = number
  default     = null
}

variable "read_replicas_mode" {
  description = "Read replicas mode."
  type        = string
  default     = "READ_REPLICAS_DISABLED"
  validation {
    condition     = can(regex("READ_REPLICAS_(ENABLED|DISABLED|MODE_UNSPECIFIED)", var.read_replicas_mode))
    error_message = "The specified value must be one of theses: READ_REPLICAS_DISABLED, READ_REPLICAS_ENABLED, READ_REPLICAS_MODE_UNSPECIFIED"
  }
}

variable "alternative_location_id" {
  description = "The alternative zone where the instance will be provisioned."
  type        = string
  default     = null
}

variable "redis_version" {
  description = "The version of Redis software."
  type        = string
  default     = null
}

variable "redis_configs" {
  description = "The Redis configuration parameters."
  type        = map(any)
  default     = {}
}

variable "display_name" {
  description = "An arbitrary and optional user-provided name for the instance."
  type        = string
  default     = null
}

variable "reserved_ip_range" {
  description = "The CIDR range of internal addresses that are reserved for this instance."
  type        = string
  default     = null
}

variable "secondary_ip_range" {
  description = "Optional. Additional IP range for node placement. Required when enabling read replicas on an existing instance."
  type        = string
  default     = null
}

variable "connect_mode" {
  description = "The connection mode of the Redis instance. Can be either DIRECT_PEERING or PRIVATE_SERVICE_ACCESS. The default connect mode if not provided is DIRECT_PEERING."
  type        = string
  default     = null
}

variable "labels" {
  description = "The resource labels to represent user provided metadata."
  type        = map(string)
  default     = null
}

variable "auth_enabled" {
  description = "Indicates whether OSS Redis AUTH is enabled for the instance. If set to true AUTH is enabled on the instance."
  type        = bool
  default     = false
}

variable "transit_encryption_mode" {
  description = "The TLS mode of the Redis instance, If not provided, TLS is enabled for the instance."
  type        = string
  default     = "SERVER_AUTHENTICATION"
}

variable "maintenance_policy" {
  description = "The maintenance policy for an instance."
  # type = object(any)
  type = object({
    day = string
    start_time = object({
      hours   = number
      minutes = number
      seconds = number
      nanos   = number
    })
  })
  default = null
}

variable "customer_managed_key" {
  description = "Default encryption key to apply to the Redis instance. Defaults to null (Google-managed)."
  type        = string
  default     = null
}

variable "persistence_config" {
  description = "The Redis persistence configuration parameters."
  type = object({
    persistence_mode        = string
    rdb_snapshot_period     = string
    rdb_snapshot_start_time = string
  })
  default = null
}
