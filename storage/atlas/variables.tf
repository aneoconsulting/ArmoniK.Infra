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

variable "vpce_id" {
  description = "Private Endpoint VPC id"
  type        = string
}
