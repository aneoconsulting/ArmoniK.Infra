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
