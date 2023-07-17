
# # Tags
# variable "tags" {
#   description = "Tags for resource"
#   type        = any
#   default     = {}
# }

# Profile
variable "project_id" {
  description = "Project ID on which to create artifact registry (AR)"
  type        = string
}

# KMS to encrypt GCP repositories
variable "kms_key" {
  description = "KMS to encrypt GCP repositories"
  type        = string
  default     = ""
}

variable "zone" {
  description = "Zone of the project"
  type        = string
}

variable "region" {
  description = "Region of the project"
  type        = string
}

variable "credentials_file" {
  description = "Path to credential json file"
  type        = string
  validation {
    condition     = can(regex(".*\\.json", var.credentials_file))
    error_message = "The value of credentials_file need to be a json"
  }
}

variable "registryName" {
  description = "Name of the registry to create"
  type        = string
}

variable "registryFormat" {
  description = "Format of packages that are going to be stocked inside the registry"
  type        = string
}

variable "registryLabels" {
  description = "Labels for the registry"
  type        = map(string)
}

variable "registryImages" {
  description = "Images to push inside the registry"
  type = map(object({
    image = string
    tag   = string
  }))
}

variable "registryDescription" {
  description = "Description of the registry"
  type        = string
}