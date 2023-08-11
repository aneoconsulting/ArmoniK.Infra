variable "name" {
  description = "The resource name of the instance."
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the memcache instance."
  type        = number
}

variable "cpu_count" {
  description = "Number of CPUs per node."
  type        = number
  validation {
    condition     = 2 <= var.cpu_count && var.cpu_count <= 32
    error_message = "Number of CPUs per node must be within range [2, 32]."
  }
  validation {
    condition     = var.cpu_count % 2 == 0
    error_message = "Number of CPUs per node must be an even number."
  }
}

variable "memory_size_mb" {
  description = "Memory size in Mebibytes for each memcache node."
  type        = number
}

variable "display_name" {
  description = " A user-visible name for the instance."
  type        = string
  default     = null
}

variable "labels" {
  description = "Resource labels to represent user-provided metadata."
  type        = map(string)
  default     = null
}

variable "zones" {
  description = "Zones where memcache nodes should be provisioned. If not provided, all zones will be used."
  type        = set(string)
  default     = null
}

variable "authorized_network" {
  description = "TThe full name of the GCE network to connect the instance to. If not provided, 'default' will be used."
  type        = string
  default     = null
}

variable "memcache_version" {
  description = "The major version of Memcached software. If not provided, latest supported version will be used."
  type        = string
  default     = null
}

variable "memcache_parameters" {
  description = "User-specified parameters for this memcache instance. [Supported configuration for Memcached Instance](https://cloud.google.com/memorystore/docs/memcached/supported-memcached-configurations)."
  type        = map(string)
  default     = null
}

variable "maintenance_policy" {
  description = "Maintenance policy for an instance. For more information see [maintenance_policy](https://registry.terraform.io/providers/hashicorp/google/4.77.0/docs/resources/memcache_instance)."
  type = object({
    day      = string
    duration = string
    start_time = object({
      hours   = number
      minutes = number
      seconds = number
      nanos   = number
    })
  })
  default = null
}
