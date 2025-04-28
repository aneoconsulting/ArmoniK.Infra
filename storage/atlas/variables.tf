variable "public_key" {
  description = "The public API key for MongoDB Atlas"
  type        = string
}
variable "private_key" {
  description = "The private API key for MongoDB Atlas"
  type        = string
}

variable "project_id" {
  description = "Atlas project ID"
  type        = string
}
variable "cluster_name" {
  description = "Atlas cluster name"
  default     = "aws-private-connection"
  type        = string
}
variable "namespace" {
  description = "Kubernetes namespace for secrets."
  type        = string
}
variable "region" {
  description = "AWS region for the private endpoint."
  type        = string
}
