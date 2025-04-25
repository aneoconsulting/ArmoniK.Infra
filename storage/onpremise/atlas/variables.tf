variable "atlas_project_id" {
  description = "MongoDB Atlas Project ID."
  type        = string
}

variable "atlas_cluster_name" {
  description = "MongoDB Atlas Cluster Name."
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

variable "vpce_mongodb_atlas_endpoint_id" {
  description = "The VPC Endpoint ID for the MongoDB Atlas connection."
  type        = string
}

variable "public_key" {
  description = "MongoDB Atlas public API key."
  type        = string
}

variable "private_key" {
  description = "MongoDB Atlas private API key."
  type        = string
}