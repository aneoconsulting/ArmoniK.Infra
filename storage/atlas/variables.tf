variable "atlas" {
  description = "Atlas project parameters"
  type = object({
    cluster_name = string
    project_id   = string
  })
}

variable "namespace" {
  description = "Kubernetes namespace for secrets."
  type        = string
}
variable "region" {
  description = "AWS region for the private endpoint."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to use for creating a VPC endpoint for MongoDB Atlas"
  type        = string
}

variable "endpoint_id" {
  description = "Existing VPC Endpoint ID for MongoDB Atlas PrivateLink (starting with vpce-)"
  type        = string
  default     = null
}
