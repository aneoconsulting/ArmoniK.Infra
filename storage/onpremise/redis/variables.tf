# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

# Parameters for Redis
variable "redis" {
  description = "Parameters of Redis"
  type = object({
    image              = string
    tag                = string
    node_selector      = any
    image_pull_secrets = string
    max_memory         = string
    max_memory_samples = number
  })
}

variable "validity_period_hours" {
  description = "Validity period of the certificate in hours"
  type        = string
  default     = "8760" # 1 year
}

variable "object_storage_adapter" {
  description = "Name of the adapter's"
  type        = string
  default     = "ArmoniK.Adapters.Redis.ObjectStorage"
}

variable "path" {
  description = "Path for mounting secrets"
  type        = string
  default     = "/redis"
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
