variable "region" {
  description = "Region"
  type        = string
}

variable "prefix" {
  description = "Prefix to use for SQS queues"
  type        = string
}

variable "tags" {
  description = "Tags for resource"
  type        = map(string)
  default     = {}
}

variable "service_account_role_name" {
  description = "Name of the IAM role to give the SQS permissions to"
  type        = string
}
