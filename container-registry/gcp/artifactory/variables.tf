variable "project_id" {
  description = "Project ID on which to create artifact registry (AR)"
  type        = string
}

variable "kms_key" {
  description = "KMS to encrypt GCP repositories"
  type        = string
  default     = null
}

variable "zone" {
  description = "Zone of the project"
  type        = string
  default     = null
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

variable "registry_name" {
  description = "Name of the registry to create"
  type        = string
}

variable "registry_labels" {
  description = "Labels for the registry"
  type        = map(string)
  default     = null
}

variable "registry_images" {
  description = "Images to push inside the registry"
  type        = map(object({
    image = string
    tag   = string
  }))
}

variable "registry_description" {
  description = "Description of the registry"
  type        = string
}

variable "immutable_tags" {
  description = "If the registry is a docker format then tags can be immutable (true or false)"
  type        = bool
  default     = null
}

variable "registry_iam" {
  description = "Assign role on the repository for a list of users"
  type        = map(list(string))
  default = null
}
