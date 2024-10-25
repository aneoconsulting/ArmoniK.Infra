# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for windows exporter"
  type = object({
    image              = string
    tag                = string
    image_pull_secrets = string
  })
}

# Node selector
variable "node_selector" {
  description = "Node selector for windows exporter"
  type        = any
  default     = {}
}
