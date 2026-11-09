data "google_client_config" "current" {}

locals {
  project  = data.google_client_config.current.project
  location = coalesce(var.location, data.google_client_config.current.region)
  registry = "${local.location}-docker.pkg.dev"
  labels   = merge(var.labels, { module = "artifact-registry-remote" })

  # Secret of each credentials version (projects/<p>/secrets/<s>/versions/<v> -> projects/<p>/secrets/<s>), keyed by
  # repository: the version may be created in the same apply, unknown at plan time
  secrets = {
    for key, repository in var.repositories :
    key => regex("^(projects/[^/]+/secrets/[^/]+)/versions/[^/]+$", repository.credentials.password_secret_version)[0]
    if repository.credentials != null
  }

  # Keyed by the static names of var.readers, the members may be unknown at plan time
  readers = merge([
    for key in keys(var.repositories) : {
      for name, member in var.readers : "${key}/${name}" => { repository = key, member = member }
    }
  ]...)
}

# The Artifact Registry service agent reads the upstream credentials. It only exists once created, which this does
# before it is granted the secrets.
resource "google_project_service_identity" "artifact_registry" {
  count    = length(local.secrets) > 0 ? 1 : 0
  provider = google-beta
  project  = local.project
  service  = "artifactregistry.googleapis.com"
}

# The email comes back before IAM knows the account, and the repository creation checks the credentials against the
# upstream. IAM changes are eventually consistent, typically within 2 minutes:
# https://cloud.google.com/iam/docs/access-change-propagation
resource "time_sleep" "artifact_registry" {
  count           = length(local.secrets) > 0 ? 1 : 0
  create_duration = "30s"
  triggers = {
    member = google_project_service_identity.artifact_registry[0].member
  }
}

resource "google_secret_manager_secret_iam_member" "credentials" {
  for_each  = local.secrets
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = time_sleep.artifact_registry[0].triggers.member
}

resource "google_artifact_registry_repository" "remote" {
  for_each      = var.repositories
  project       = local.project
  location      = local.location
  repository_id = "${var.name}-${each.key}"
  description   = coalesce(each.value.description, "Pull-through cache of ${each.value.docker_hub ? "Docker Hub" : each.value.uri}")
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"
  labels        = local.labels

  remote_repository_config {
    docker_repository {
      public_repository = each.value.docker_hub ? "DOCKER_HUB" : null
      dynamic "custom_repository" {
        for_each = each.value.docker_hub ? [] : [each.value.uri]
        content {
          uri = custom_repository.value
        }
      }
    }
    dynamic "upstream_credentials" {
      for_each = each.value.credentials != null ? [each.value.credentials] : []
      content {
        username_password_credentials {
          username                = upstream_credentials.value.username
          password_secret_version = upstream_credentials.value.password_secret_version
        }
      }
    }
  }

  cleanup_policy_dry_run = false
  dynamic "cleanup_policies" {
    for_each = var.cleanup_older_than != null ? [var.cleanup_older_than] : []
    content {
      id     = "delete-older-than"
      action = "DELETE"
      condition {
        tag_state  = "ANY"
        older_than = cleanup_policies.value
      }
    }
  }

  depends_on = [google_secret_manager_secret_iam_member.credentials]
}

resource "google_artifact_registry_repository_iam_member" "readers" {
  for_each   = local.readers
  project    = local.project
  location   = local.location
  repository = google_artifact_registry_repository.remote[each.value.repository].name
  role       = "roles/artifactregistry.reader"
  member     = each.value.member
}
