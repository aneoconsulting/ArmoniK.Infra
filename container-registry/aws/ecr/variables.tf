# Profile
variable "aws_profile" {
  description = "AWS Profile used to login and push container images on ECR"
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
  default     = null
}

# Variable to enable mutability
variable "mutability" {
  description = "The tag mutability setting for the repository"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.mutability)
    error_message = "Valid values for \"mutability\" : \"MUTABLE\" | \"IMMUTABLE\"."
  }
}

# List of ECR repositories to create
variable "repositories" {
  description = "Map of ECR repositories to create. Each repository is an object of \"image\" and \"tag\" parameters"
  type = map(object({
    image = string
    tag   = string
  }))
  default = {}
}

variable "scan_on_push" {
  description = " Indicates whether images are scanned after being pushed to the repository or not scanned"
  type        = bool
  default     = null
}

variable "force_delete" {
  description = "If true, will delete the repository even if it contains images."
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "The encryption type to use for the repository."
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Valid values for \"encryption_type\" are: \"AES256\" | \"KMS\"."
  }
}

variable "only_pull_accounts" {
  description = "List of accounts having pull permission"
  type        = list(string)
  default     = []
}

variable "push_and_pull_accounts" {
  description = "List of accounts having push and pull permissions"
  type        = list(string)
  default     = []
}

variable "lifecycle_policy" {
  description = "Manages an ECR repository lifecycle policy"
  type        = map(any)
  default     = null
}
