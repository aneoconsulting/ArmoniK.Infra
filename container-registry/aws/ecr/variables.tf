# Profile
variable "aws_profile" {
  description = "Profile of AWS credentials to deploy Terraform sources"
  type        = string
}

# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

# KMS to encrypt ECR repositories
variable "kms_key_id" {
  description = "KMS to encrypt ECR repositories"
  type        = string
  default     = ""
}

# Variable to enable mutability
variable "mutability" {
  description = "Variable to enable mutability"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.mutability)
    error_message = "Valid values for \"mutability\" : \"MUTABLE\" | \"IMMUTABLE\"."
  }
}

# List of ECR repositories to create
variable "repositories" {
  description = "List of ECR repositories to create"
  type = map(object({
    image = string
    tag   = string
  }))
  default = {}
}
