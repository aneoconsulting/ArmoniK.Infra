variable "name" {
  description = "Name of service account name."
  type        = string
}

variable "automount_service_account_token" {
  description = "To enable automatic mounting of the Kubernetes service account token."
  type        = bool
  default     = true
}

variable "kubernetes_namespace" {
  description = "Namespace within which name of the service account must be unique."
  type        = string
  default     = "default"
}

variable "roles" {
  description = "A list of roles to be added to the created service account."
  type        = set(string)
  default     = []
}
