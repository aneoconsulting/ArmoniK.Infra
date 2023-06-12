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
  })
}
