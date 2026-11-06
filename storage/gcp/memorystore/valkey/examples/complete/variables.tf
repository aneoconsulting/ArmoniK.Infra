variable "region" {
  description = "The GCP region used by the provider"
  type        = string
  default     = "europe-west9"
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "kube_config_path" {
  description = "Path of the kubeconfig of the cluster where the CA secret is created"
  type        = string
  default     = "~/.kube/config"
}
