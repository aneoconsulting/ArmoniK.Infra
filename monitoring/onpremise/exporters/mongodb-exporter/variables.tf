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

# variable "certif_mount" {
#   description = "MongoDB certificate mount secret"
#   type = map(object({
#     secret = string
#     path   = string
#     mode   = string
#   }))
#   default = {}
# }

variable "force_split_cluster" {
  description = "Used when working with mongodb+srv URIs (this is typically the case with Atlas-managed MongoDB), it adds the '--split-cluster' flag to the exporter flags. You can force this to be on."
  type        = bool
  default     = false
}

# variable "mongo_url" {
#   description = "Full MongoDB URI with credentials and tls options included"
#   type        = string
#   default     = ""
# }


variable "mongodb_modules" {
  type = list(any) 
}