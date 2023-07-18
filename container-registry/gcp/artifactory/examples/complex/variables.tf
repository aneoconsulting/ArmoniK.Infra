variable "zone" {
  description = "Zone of the project"
  type        = string
  default     = "a"
}

variable "region" {
  description = "Region of the project"
  type        = string
  default     = "europe-west9"
}

variable "project_id" {
  description = "ID of the project"
  type        = string
  default     = "test-project"
}

variable "registry_name" {
  description = "Name of the registry to create"
  type        = string
  default     = "test-registry"
}

variable "kms_key" {
  description = "KMS to encrypt GCP repositories"
  type        = string
  default     = null
}
