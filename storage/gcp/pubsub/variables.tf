variable "project_id" {
  description = "Id of the google project"
  type        = string
}

variable "kms_key_id" {
  description = "Id of the crypto KMS used to encrypt/decrypt resources"
  type        = string
}

variable "prefix" {
  description = "Prefix of the topic and subscription name"
  type        = string
  default     = ""
}
