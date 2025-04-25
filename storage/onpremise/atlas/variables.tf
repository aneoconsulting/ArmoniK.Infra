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

variable "enable_private_endpoint" {
  description = "Whether to create a private endpoint for MongoDB Atlas"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region where the private endpoint should be created"
  type        = string
  default     = ""
}

variable "aws_endpoint_id" {
  description = "AWS VPC endpoint ID to connect to MongoDB Atlas"
  type        = string
  default     = ""
}
