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

# New variables for multi-PSC support
variable "nb_psc" {
  description = "Number of PSC endpoints to deploy. If null, only one PSC is created"
  type        = number
  default     = null
}

variable "addresses" {
  description = "List of IP addresses that should be allocated for the endpoints"
  type        = list(string)
  default     = []
}

variable "override_endpoint_name" {
  description = "Base name of the endpoint. If null, it will be computed from namespace and cluster name"
  type        = string
  default     = null
}
