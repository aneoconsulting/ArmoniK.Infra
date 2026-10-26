variable "kubernetes_namespace" {
  description = "Namespace of the Kubernetes service account."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$", var.kubernetes_namespace))
    error_message = "\"kubernetes_namespace\" must be a valid Kubernetes namespace name (RFC 1123 label)."
  }
}

variable "kubernetes_service_account" {
  description = "Name of the Kubernetes service account, created outside this module (by the ArmoniK charts for instance)."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9.]{0,251}[a-z0-9])?$", var.kubernetes_service_account))
    error_message = "\"kubernetes_service_account\" must be a valid Kubernetes service account name (RFC 1123 subdomain)."
  }
}

variable "project_roles" {
  description = "Roles granted on the whole project. Prefer granting roles on each resource with the member output."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "cluster_project_id" {
  description = "Project of the GKE cluster, which owns the workload identity pool. Defaults to the provider project."
  type        = string
  default     = null
}
