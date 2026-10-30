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

variable "create_service_account" {
  description = "Create the Kubernetes service account. Set false when another module owns it, such as the ArmoniK charts: only the IAM resources are created, and with iam_service_account that module annotates its service account with service_account_email."
  type        = bool
  default     = true
}

variable "iam_service_account" {
  description = "Create an IAM service account that the Kubernetes service account impersonates, and grant it the roles. When false, Workload Identity Federation for GKE grants the roles to the Kubernetes service account itself (the member output), which needs no annotation and may be created after the roles."
  type        = bool
  default     = true
}

variable "cluster_project_id" {
  description = "Project of the GKE cluster, which owns the workload identity pool, when iam_service_account is false. Defaults to the provider project."
  type        = string
  default     = null
}
