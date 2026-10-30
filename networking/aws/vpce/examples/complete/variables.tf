variable "aws_region" {
  description = "The AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "aws_profile" {
  description = "The AWS profile"
  type        = string
  default     = "default"
}

variable "lattice_resource_configuration_arn" {
  description = "ARN of an existing VPC Lattice Resource Configuration, to exercise the Resource endpoint type. Leave null to skip it."
  type        = string
  default     = null
}

variable "lattice_service_network_arn" {
  description = "ARN of an existing VPC Lattice Service Network, to exercise the ServiceNetwork endpoint type. Leave null to skip it."
  type        = string
  default     = null
}

variable "sts_service_region" {
  description = "AWS region hosting the sts VPC endpoint service, to exercise a cross-region Interface endpoint. Leave null for the same region as aws_region."
  type        = string
  default     = null
}
