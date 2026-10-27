# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

variable "region" {
  description = "AWS region where the log group will be managed. Defaults to the region set in the provider configuration"
  type        = string
  default     = null
}

# Name
variable "name" {
  description = "Name of group log"
  type        = string
}

# KMS to encrypt the log group
variable "kms_key_id" {
  description = "ARN of the KMS key encrypting the log data"
  type        = string
  default     = ""
}

# Retention in days
variable "retention_in_days" {
  description = "Retention in days of logs"
  type        = number
}

variable "log_group_class" {
  description = "Log class of the log group: STANDARD, INFREQUENT_ACCESS or DELIVERY. Changing it replaces the log group, deleting its logs. Defaults to STANDARD"
  type        = string
  default     = null
  validation {
    condition     = contains(["STANDARD", "INFREQUENT_ACCESS", "DELIVERY"], coalesce(var.log_group_class, "STANDARD"))
    error_message = "Valid values for \"log_group_class\" are: \"STANDARD\" | \"INFREQUENT_ACCESS\" | \"DELIVERY\"."
  }
}

variable "deletion_protection_enabled" {
  description = "Whether the log group is protected against deletion. Once enabled, disabling it requires setting false explicitly, null leaving the current setting unmanaged"
  type        = bool
  default     = null
}
