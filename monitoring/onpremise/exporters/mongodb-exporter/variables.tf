# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for partition metrics exporter"
  type = object({
    image              = string
    tag                = string
    image_pull_secrets = string
  })
}

variable "certif_mount" {
  description = "MongoDB certificate mount secret"
  type = map(object({
    secret = string
    path   = string
    mode   = string
  }))
}

variable "mongo_url" {
  description = "Full MongoDB URI with credentials and tls options included"
  type        = string
}
