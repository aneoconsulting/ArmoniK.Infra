
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
variable "kms_key_name" {
  description = "KMS to encrypt GCP repositories"
  type        = string
  default     = ""
}

# List of AR repositories to create
variable "repositories" {
  description = "List of AR repositories to create"
  type = list(object({
    location      = string
    repository_id = string
    description   = string
    format        = string
  }))

  default = [
    {
      location      = "aneo.fr"
      repository_id = "my-id-repository"
      description   = "my first artifact registry with TF"
      format        = "docker"
    }
  ]
}
