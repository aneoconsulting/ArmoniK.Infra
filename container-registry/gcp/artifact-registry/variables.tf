variable "name" {
  description = "Name of the virtual repository, and prefix of the repositories behind it"
  type        = string
  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.name))
    error_message = "The name must start with a lowercase letter and contain only lowercase letters, digits and hyphens."
  }
}

variable "description" {
  description = "Description of the virtual repository"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels for the repositories"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "kms_key_id" {
  description = "KMS key name to encrypt the remote and standard repositories. Has the form: projects/{{my-project}}/locations/{{my-region}}/keyRings/{{my-kr}}/cryptoKeys/{{my-key}}"
  type        = string
  default     = null
}

variable "remote_repositories" {
  description = "Pull-through caches of public registries, keyed by a short name used as suffix of the repository name. Each one sets either `public_repository` (DOCKER_HUB) or the `uri` of the registry, and its `priority` in the virtual repository (the highest is tried first)"
  type = map(object({
    public_repository = optional(string)
    uri               = optional(string)
    priority          = number
    description       = optional(string)
  }))
  default = {
    dockerhub  = { public_repository = "DOCKER_HUB", priority = 50 }
    ecr-public = { uri = "https://public.ecr.aws", priority = 40 }
    quay       = { uri = "https://quay.io", priority = 30 }
    ghcr       = { uri = "https://ghcr.io", priority = 20 }
    k8s        = { uri = "https://registry.k8s.io", priority = 10 }
  }
  nullable = false
  validation {
    condition     = alltrue([for repository in values(var.remote_repositories) : (repository.public_repository == null) != (repository.uri == null)])
    error_message = "Each remote repository sets exactly one of \"public_repository\" or \"uri\"."
  }
  validation {
    condition     = alltrue([for repository in values(var.remote_repositories) : contains(["DOCKER_HUB"], coalesce(repository.public_repository, "DOCKER_HUB"))])
    error_message = "The only \"public_repository\" for Docker is \"DOCKER_HUB\"."
  }
  validation {
    condition     = !contains(keys(var.remote_repositories), "private")
    error_message = "\"private\" is the name of the standard repository and cannot name a remote repository."
  }
}

variable "standard_repository" {
  description = "Optional repository for images pushed by their owner, such as private workers, placed in the virtual repository with `priority`. `iam_roles` grants roles on it, for instance the writer role to a CI"
  type = object({
    immutable_tags = optional(bool, true)
    priority       = optional(number, 100)
    iam_roles      = optional(map(set(string)), {})
  })
  default = null
}

variable "iam_roles" {
  description = "Roles to grant on the virtual repository, as a map of role to members"
  type        = map(set(string))
  default     = {}
  nullable    = false
}
