variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
  default     = "armonik"
}

variable "region" {
  type = string
}

variable "prefix" {
  description = "Prefix to use for SQS queues"
  type        = string
}
