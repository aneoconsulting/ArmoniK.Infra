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

variable "service_account_name" {
  description = "Name of the service account to create"
  type = string
}