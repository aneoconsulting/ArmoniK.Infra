variable "name" {
  description = "The ID of the instance or a fully qualified identifier for the instance."
  type        = string
}

variable "memory_size_gb" {
  description = "Redis memory size in GiB."
  type        = number
}

variable "auth_enabled" {
  description = "Indicates whether OSS Redis AUTH is enabled for the instance. If set to true AUTH is enabled on the instance."
  type        = bool
  default     = false
}

variable "authorized_network" {
  description = "The full name of the Google Compute Engine network to which the instance is connected. If left unspecified, the default network will be used."
  type        = string
  default     = null
}

variable "connect_mode" {
  description = "The connection mode of the Redis instance. Can be either DIRECT_PEERING or PRIVATE_SERVICE_ACCESS. The default connect mode if not provided is DIRECT_PEERING."
  type        = string
  default     = "DIRECT_PEERING"
  validation {
    condition     = contains(["DIRECT_PEERING", "PRIVATE_SERVICE_ACCESS"], var.connect_mode)
    error_message = "Valid values fir \"connect_mode\" are: \"DIRECT_PEERING\" | \"PRIVATE_SERVICE_ACCESS\"."
  }
}

variable "display_name" {
  description = "An arbitrary and optional user-provided name for the instance."
  type        = string
  default     = null
}

variable "labels" {
  description = "The resource labels to represent user provided metadata."
  type        = map(string)
  default     = null
}

variable "locations" {
  description = "The zones where the instance will be provisioned. If two zones are given, HA is enabled."
  type        = set(string)
  default     = []
  validation {
    condition     = length(var.locations) <= 2
    error_message = "The list \"locations\" must contain one or two elements."
  }
}

variable "redis_configs" {
  description = "The Redis configuration parameters. See documentation in [Supported Redis configuration](https://cloud.google.com/memorystore/docs/redis/supported-redis-configurations)."
  type        = map(any)
  default     = {}
}

variable "persistence_config" {
  description = "The Redis persistence configuration parameters. For more information see [persistence_config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/redis_instance)."
  type = object({
    persistence_mode        = string
    rdb_snapshot_period     = string
    rdb_snapshot_start_time = string
  })
  default = null
}

variable "maintenance_policy" {
  description = "The maintenance policy for an instance. For more information see [maintenance_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/redis_instance)."
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

variable "redis_version" {
  description = "The version of Redis software."
  type        = string
  default     = null
}

variable "reserved_ip_range" {
  description = "The CIDR range of internal addresses that are reserved for this instance."
  type        = string
  default     = null
}

variable "tier" {
  description = "The service tier of the instance."
  type        = string
  default     = "BASIC"
  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.tier)
    error_message = "Valid values for \"tier\" are: \"BASIC\" | \"STANDARD_HA\"."
  }
}

variable "transit_encryption_mode" {
  description = "The TLS mode of the Redis instance, If not provided, TLS is enabled for the instance."
  type        = string
  default     = "SERVER_AUTHENTICATION"
  validation {
    condition     = contains(["DISABLED", "SERVER_AUTHENTICATION"], var.transit_encryption_mode)
    error_message = "Valid values for \"transit_encryption_mode\" are: \"DISABLED\" | \"SERVER_AUTHENTICATION\"."
  }
}

variable "replica_count" {
  description = "The number of replicas."
  type        = number
  default     = null
  validation {
    condition     = 0 <= coalesce(var.replica_count, 0) && coalesce(var.replica_count, 5) <= 5
    error_message = "Valid values for \"replica_count\" are : [0,5]."
  }
}

variable "read_replicas_mode" {
  description = "Read replicas mode."
  type        = string
  default     = "READ_REPLICAS_DISABLED"
  validation {
    condition     = contains(["READ_REPLICAS_DISABLED", "READ_REPLICAS_ENABLED"], var.read_replicas_mode)
    error_message = "Valid values for \"read_replicas_mode\" are: \"READ_REPLICAS_DISABLED\" | \"READ_REPLICAS_ENABLED\"."
  }
}

variable "secondary_ip_range" {
  description = "Optional. Additional IP range for node placement. Required when enabling read replicas on an existing instance. See [secondary_ip_range](https://registry.terraform.io/providers/hashicorp/google/4.77.0/docs/resources/redis_instance)."
  type        = string
  default     = null
}

variable "customer_managed_key" {
  description = "Default encryption key to apply to the Redis instance. Defaults to null (Google-managed)."
  type        = string
  default     = null
}

variable "object_storage_adapter" {
  description = "Name of the adapter's"
  type        = string
  default     = "ArmoniK.Adapters.Redis.ObjectStorage"
}

variable "client_name" {
  description = "Name of the redis client"
  type        = string
  default     = "ArmoniK.Core"
}

variable "instance_name" {
  description = "Name of the instance"
  type        = string
  default     = "ArmoniKRedis"
}

variable "ssl_option" {
  description = "Ssl option"
  type        = string
  default     = "true"
}

variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
  default     = "armonik"
}

variable "adapter_class_name" {
  description = "Name of the adapter's class"
  type        = string
  default     = "ArmoniK.Core.Adapters.Redis.ObjectBuilder"
}

variable "adapter_absolute_path" {
  description = "The adapter's absolute path"
  type        = string
  default     = "/adapters/object/redis/ArmoniK.Core.Adapters.Redis.dll"
}
