variable "gcp_sa_name" {
  type        = string
  description = "GCP service account name"
  default     = null
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
  default     = null
}

variable "automount_service_account_token" {
  type        = bool
  description = "To enable automatic mounting of the service account token"
  default     = true
}

variable "k8s_sa_name" {
  type        = string
  description = "Name of Kubernetes service account"
  default     = null
}

variable "K8s_namespace" {
  type        = string
  description = "Namespace within which name of the service account must be unique"
  default     = "default"
}

variable "roles" {
  description = "A list of roles to be added to the created service account"
  type        = set(string)
  default     = []
}
