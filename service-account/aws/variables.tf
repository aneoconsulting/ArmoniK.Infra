variable "prefix" {
  description = "Prefix to use for service account related resources"
  type        = string
}

# Tags
variable "tags" {
  description = "Tags for resource"
  type        = map(string)
  default     = {}
}

variable "namespace" {
  description = "Namespace of ArmoniK service account related resources"
  type        = string
  default     = "armonik"
}

variable "name" {
  description = "Name of the service account to create"
  type        = string
}

variable "automount_token" {
  description = "To enable automatic mounting of the Kubernetes service account token."
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  type        = string
}

variable "oidc_issuer_url" {
  description = "URL of the OIDC issuer"
  type        = string
}

variable "pod_identity" {
  description = "Whether EKS Pod Identity is deployed on the cluster (the pod_identity output of kubernetes/aws/eks). When true, the service account gets its role through a Pod Identity association instead of the IRSA annotation, which requires an AWS SDK supporting it. The role trusts both, so switching only takes a pod restart"
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "Name of the EKS cluster, required when pod_identity is true; when set, the role's Pod Identity trust is also pinned to this cluster"
  type        = string
  default     = null
}
