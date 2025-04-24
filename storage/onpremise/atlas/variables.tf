variable "atlas" {
  description = "Atlas project parameters"
  type = object({
    cluster_name = string
    project_id   = string
  })
}

variable "namespace" {
  description = "Kubernetes namespace where secrets will be created"
  type        = string
}

variable "mongodb_atlas_public_key" {
  type        = string
  description = "MongoDB Atlas public API key"
  sensitive   = true
}

variable "mongodb_atlas_private_key" {
  type        = string
  description = "MongoDB Atlas private API key"
  sensitive   = true
}

variable "download_atlas_certificate" {
  description = "Whether to automatically download the MongoDB Atlas CA certificate"
  type        = bool
  default     = false
}
