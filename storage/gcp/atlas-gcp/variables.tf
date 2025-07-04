variable "cluster_name" {
  description = "Name of the MongoDB Atlas cluster"
  type        = string
}

variable "project_id" {
  description = "ID of the MongoDB Atlas project"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for secrets."
  type        = string
}

variable "region" {
  description = "GCP region for the private endpoint."
  type        = string
}

variable "vpc_network" {
  description = "The GCP VPC network for Private Service Connect"
  type        = string
}

variable "gke_subnet" {
  description = "The GKE subnet for Private Service Connect"
  type        = string
}

variable "ip_address" {
  description = "Optional static IP address for the forwarding rule"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}

variable "gcp_project_id" {
  description = "The GCP project ID where resources will be created. If not provided, uses the default project from the provider."
  type        = string
  default     = null
}
