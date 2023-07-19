variable "region" {
  description = "The GCP region to use."
  type        = string
  default     = null
}

variable "project" {
  description = "The ID of the project in which the resource belongs to."
  type        = string
}

variable "enable_apis" {
  description = "Flag for enabling redis.googleapis.com in your project"
  type        = bool
  default     = true
}

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
  description = "The service tier of the instance. https://cloud.google.com/memorystore/docs/redis/reference/rest/v1/projects.locations.instances#Tier"
  type        = string
  default     = "STANDARD_HA"
}

variable "memory_size_gb" {
  description = "Redis memory size in GiB. Defaulted to 1 GiB"
  type        = number
  default     = 1
}

variable "replica_count" {
  description = "The number of replicas. can"
  type        = number
  default     = null
}

variable "read_replicas_mode" {
  description = "Read replicas mode. https://cloud.google.com/memorystore/docs/redis/reference/rest/v1/projects.locations.instances#readreplicasmode "
  type        = string
  default     = "READ_REPLICAS_DISABLED"
}

variable "location_id" {
  description = "The zone where the instance will be provisioned. If not provided, the service will choose a zone for the instance. For STANDARD_HA tier, instances will be created across two zones for protection against zonal failures. If [alternativeLocationId] is also provided, it must be different from [locationId]."
  type        = string
  default     = null
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
  description = "The Redis configuration parameters. See [more details](https://cloud.google.com/memorystore/docs/redis/reference/rest/v1/projects.locations.instances#Instance.FIELDS.redis_configs)"
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
  description = "The Redis persistence configuration parameters. https://cloud.google.com/memorystore/docs/redis/reference/rest/v1/projects.locations.instances#persistenceconfig"
  type = object({
    persistence_mode        = string
    rdb_snapshot_period     = string
    rdb_snapshot_start_time = string
  })
  default = null
}

############## SECTION - PROJECT SERVICE

variable "enable_apis_ps" {
  description = "Whether to actually enable the APIs. If false, this module is a no-op."
  type        = bool
  default     = true
}

variable "activate_apis" {
  description = "The list of apis to activate within the project"
  type        = list(string)
  default     = []
}

variable "activate_api_identities" {
  description = <<EOF
    The list of service identities (Google Managed service account for the API) to force-create for the project (e.g. in order to grant additional roles).
    APIs in this list will automatically be appended to `activate_apis`.
    Not including the API in this list will follow the default behaviour for identity creation (which is usually when the first resource using the API is created).
    Any roles (e.g. service agent role) must be explicitly listed. See https://cloud.google.com/iam/docs/understanding-roles#service-agent-roles-roles for a list of related roles.
  EOF
  type = list(object({
    api   = string
    roles = list(string)
  }))
  default = []
}

variable "disable_services_on_destroy" {
  description = "Whether project services will be disabled when the resources are destroyed. https://www.terraform.io/docs/providers/google/r/google_project_service.html#disable_on_destroy"
  default     = true
  type        = bool
}

variable "disable_dependent_services" {
  description = "Whether services that are enabled and which depend on this service should also be disabled when this service is destroyed. https://www.terraform.io/docs/providers/google/r/google_project_service.html#disable_dependent_services"
  default     = true
  type        = bool
}
