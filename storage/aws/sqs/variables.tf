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

variable "policy_creation_delay_in_ms" {
  description = "Milliseconds to wait between creating the IAM policy and setting its version as default; the provider documents it as possibly required in environments with very high S3 IO loads. Requires the iam:SetDefaultPolicyVersion permission"
  type        = number
  default     = null
}
