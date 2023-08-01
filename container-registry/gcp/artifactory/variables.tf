variable "kms_key" {
  description = "KMS to encrypt GCP repositories"
  type        = string
  default     = null
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
  type = map(object({
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
  default     = null
}
