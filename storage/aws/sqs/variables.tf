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
  description = "Name of the IAM role associated to the AWS service account. This role will be given SQS permissions."
  type        = string
}
