variable "project" {
  description = "Project name"
  type        = string
  default     = "armonik-gcp-13469"
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
  default     = "europe-west9"
}

variable "cluster_name" {
  description = "The name for the GKE cluster"
  type        = string
  default     = "gke-complete-cluster"
}

variable "network" {
  description = "The VPC network created to host the cluster in"
  type        = string
  default     = "gke-complet-network"
}

variable "gke_subnet" {
  description = "Map of GKE subnets"
  type = object({
    name                = string
    nodes_cidr_block    = string
    pods_cidr_block     = string
    services_cidr_block = string
    region              = string
  })
  default = {
    name                = "gke-complete-subnet"
    nodes_cidr_block    = "10.51.0.0/16",
    pods_cidr_block     = "192.168.64.0/22"
    services_cidr_block = "192.168.1.0/24"
    region              = "europe-west9"
  }
}



variable "service_account" {
  description = "value"
  type        = string
  default     = "tf-gke-gke-test-1-k4hk@armonik-gcp-13469.iam.gserviceaccount.com"
}
variable "kubeconfig_path" {
  description = "value"
  type        = string
  default     = null
}
