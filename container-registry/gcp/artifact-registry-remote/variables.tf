variable "name" {
  description = "Prefix of the repository IDs, <name>-<key of repositories>: lowercase letters, digits or hyphens, starting with a letter."
  type        = string
  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{0,38}[a-z0-9])?$", var.name))
    error_message = "\"name\" must be up to 40 lowercase letters, digits or hyphens, start with a letter and not end with a hyphen."
  }
}

variable "location" {
  description = "Region of the repositories, the closest to the nodes pulling from them. Defaults to the provider region."
  type        = string
  default     = null
}

variable "repositories" {
  description = <<-EOT
    Pull-through caches, one Docker remote repository per upstream registry, keyed by a short name that ends the
    repository ID. Each one sets either docker_hub = true or the uri of another registry. An image keeps its upstream
    path behind the url of its repository: docker.io/grafana/grafana is <url of dockerhub>/grafana/grafana, and the
    official Docker Hub images take the library/ prefix (<url of dockerhub>/library/busybox).
    * credentials: username and Secret Manager secret version (projects/<project>/secrets/<secret>/versions/<version>)
      of the upstream password or token. The module lets the Artifact Registry service agent read the secret. Without
      them, the upstream sees anonymous pulls, rate limited on Docker Hub.
  EOT
  type = map(object({
    docker_hub  = optional(bool, false)
    uri         = optional(string)
    description = optional(string)
    credentials = optional(object({
      username                = string
      password_secret_version = string
    }))
  }))
  default = {
    dockerhub  = { docker_hub = true }
    ghcr       = { uri = "https://ghcr.io" }
    quay       = { uri = "https://quay.io" }
    k8s        = { uri = "https://registry.k8s.io" }
    ecr-public = { uri = "https://public.ecr.aws" }
  }
  nullable = false
  validation {
    condition     = alltrue([for key in keys(var.repositories) : can(regex("^[a-z0-9]([-a-z0-9]{0,20}[a-z0-9])?$", key))])
    error_message = "The keys of \"repositories\" must be up to 22 lowercase letters, digits or hyphens, not starting or ending with a hyphen."
  }
  validation {
    condition     = alltrue([for repository in values(var.repositories) : repository.docker_hub != (repository.uri != null)])
    error_message = "Each repository sets either \"docker_hub\" = true or \"uri\", not both."
  }
  validation {
    condition     = alltrue([for repository in values(var.repositories) : repository.uri == null || startswith(coalesce(repository.uri, "-"), "https://")])
    error_message = "The \"uri\" of a repository must start with https://."
  }
  validation {
    condition = alltrue([for repository in values(var.repositories) :
      repository.credentials == null || can(regex("^projects/[^/]+/secrets/[^/]+/versions/[^/]+$", try(repository.credentials.password_secret_version, "")))
    ])
    error_message = "\"credentials.password_secret_version\" must be projects/<project>/secrets/<secret>/versions/<version>."
  }
}

variable "readers" {
  description = "IAM members allowed to pull from every repository, keyed by a static name since the members may only be known after the apply, such as the node service account of a GKE cluster: { nodes = \"serviceAccount:<email>\" }. A pull of an image not cached yet fetches it from the upstream."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "cleanup_older_than" {
  description = "Delete the cached images older than this duration, in seconds with an s suffix (\"2592000s\": 30 days); the next pull fetches them again. Null keeps them."
  type        = string
  default     = null
  validation {
    condition     = var.cleanup_older_than == null || can(regex("^[0-9]+s$", coalesce(var.cleanup_older_than, "-")))
    error_message = "\"cleanup_older_than\" must be a number of seconds with an s suffix, such as \"2592000s\"."
  }
}

variable "labels" {
  description = "Labels of the repositories."
  type        = map(string)
  default     = {}
  nullable    = false
}
