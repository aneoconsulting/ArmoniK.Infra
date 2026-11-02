variable "kms_key_id" {
  description = "KMS key name to encrypt GCP repositories. Has the form: projects/{{my-project}}/locations/{{my-region}}/keyRings/{{my-kr}}/cryptoKeys/{{my-key}}"
  type        = string
  default     = null
}

variable "name" {
  description = "Name of the registry to create"
  type        = string
}

variable "labels" {
  description = "Labels for the registry"
  type        = map(string)
  default     = {}
}

variable "docker_images" {
  description = "Deprecated, use `pull_through_cache` instead. Docker container images to copy inside the registry from the machine running Terraform"
  type = map(list(object({
    image = string
    tag   = string
  })))
  default = {}
}

variable "description" {
  description = "Description of the registry"
  type        = string
  default     = ""
}

variable "immutable_tags" {
  description = "If the registry is a docker format then tags can be immutable (true or false)"
  type        = bool
  default     = true
}

variable "iam_roles" {
  description = "Assign role on the repository for a list of users"
  type        = map(set(string))
  default     = {}
}

variable "pull_through_cache" {
  description = <<-EOT
    Pull-through caches of public registries, behind a virtual repository that also serves the registry created by this
    module, so images pushed there take precedence over the upstream ones. Set to `{}` to enable it with the defaults.
    `remote_repositories` is keyed by a short name used as suffix of the repository name; each one sets either
    `public_repository` (DOCKER_HUB) or the `uri` of the registry, its `priority` in the virtual repository (the highest is
    tried first) and optional `credentials` to authenticate to the upstream registry (the Artifact Registry service agent
    must be able to access the secret version). `standard_priority` is the priority of the registry created by this
    module, and `iam_roles` grants roles on the virtual repository.
  EOT
  type = object({
    remote_repositories = optional(map(object({
      public_repository = optional(string)
      uri               = optional(string)
      priority          = number
      description       = optional(string)
      credentials = optional(object({
        username                = string
        password_secret_version = string
      }))
      })), {
      dockerhub  = { public_repository = "DOCKER_HUB", priority = 50 }
      ecr-public = { uri = "https://public.ecr.aws", priority = 40 }
      quay       = { uri = "https://quay.io", priority = 30 }
      ghcr       = { uri = "https://ghcr.io", priority = 20 }
      k8s        = { uri = "https://registry.k8s.io", priority = 10 }
    })
    standard_priority = optional(number, 100)
    iam_roles         = optional(map(set(string)), {})
  })
  default = null
  validation {
    condition = alltrue([
      for key in keys(try(var.pull_through_cache.remote_repositories, {})) :
      can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", key)) && !contains(["standard", "virtual"], key)
    ])
    error_message = "Remote repository keys contain only lowercase letters, digits and hyphens, and cannot be \"standard\" or \"virtual\"."
  }
  validation {
    condition = alltrue([
      for repository in values(try(var.pull_through_cache.remote_repositories, {})) :
      (repository.public_repository == null) != (repository.uri == null)
    ])
    error_message = "Each remote repository sets exactly one of \"public_repository\" or \"uri\"."
  }
  validation {
    condition = alltrue([
      for repository in values(try(var.pull_through_cache.remote_repositories, {})) :
      contains(["DOCKER_HUB"], coalesce(repository.public_repository, "DOCKER_HUB"))
    ])
    error_message = "The only \"public_repository\" for Docker is \"DOCKER_HUB\"."
  }
}
