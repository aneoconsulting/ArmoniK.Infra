# Global variables
variable "namespace" {
  description = "Kubernetes namespace to use for this resource"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for MongoDB metrics exporter"
  type = object({
    image              = string
    tag                = string
    image_pull_secrets = string
  })
}

variable "force_split_cluster" {
  description = "Used when working with mongodb+srv URIs (this is typically the case with Atlas-managed MongoDB), it adds the '--split-cluster' flag to the exporter flags. You can force this to be on."
  type        = bool
  default     = false
}

variable "disable_diagnostic_data" {
  description = "When working with a sharded on-premise MongoDB deployment, this flag works around the exporter crashing (but exports less metrics)"
  type        = bool
  default     = false
}

variable "mongodb_modules" {
  description = "MongoDB modules to use when building the exporter (assumes only one is actually active)"
  type        = any
}
