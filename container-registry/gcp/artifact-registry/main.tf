data "google_client_config" "current" {}

locals {
  location = data.google_client_config.current.region
  project  = data.google_client_config.current.project
  labels   = merge(var.labels, { module = "docker-artifact-registry" })
  upstreams = merge(
    { for key, repository in google_artifact_registry_repository.remote : key => {
      id       = repository.id
      priority = var.remote_repositories[key].priority
    } },
    var.standard_repository != null ? { private = {
      id       = google_artifact_registry_repository.standard[0].id
      priority = var.standard_repository.priority
    } } : {}
  )
}

# The Artifact Registry service agent must exist before it can be granted the key
resource "google_project_service_identity" "kms" {
  count    = var.kms_key != null ? 1 : 0
  provider = google-beta
  project  = local.project
  service  = "artifactregistry.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "kms" {
  count         = var.kms_key != null ? 1 : 0
  crypto_key_id = var.kms_key.id
  member        = "serviceAccount:${google_project_service_identity.kms[0].email}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

# Pull-through caches of the public registries
resource "google_artifact_registry_repository" "remote" {
  for_each      = var.remote_repositories
  location      = local.location
  project       = local.project
  repository_id = "${var.name}-${each.key}"
  description   = coalesce(each.value.description, "Cache of ${coalesce(each.value.uri, each.value.public_repository)}")
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"
  kms_key_name  = try(var.kms_key.id, null)
  labels        = local.labels
  remote_repository_config {
    docker_repository {
      public_repository = each.value.public_repository
      dynamic "custom_repository" {
        for_each = each.value.uri != null ? [each.value.uri] : []
        content {
          uri = custom_repository.value
        }
      }
    }
  }
  depends_on = [google_kms_crypto_key_iam_member.kms]
}

# Images pushed by their owner, such as private workers
resource "google_artifact_registry_repository" "standard" {
  count         = var.standard_repository != null ? 1 : 0
  location      = local.location
  project       = local.project
  repository_id = "${var.name}-private"
  description   = "Private images of ${var.name}"
  format        = "DOCKER"
  mode          = "STANDARD_REPOSITORY"
  kms_key_name  = try(var.kms_key.id, null)
  labels        = local.labels
  docker_config {
    immutable_tags = var.standard_repository.immutable_tags
  }
  depends_on = [google_kms_crypto_key_iam_member.kms]
}

# Single entry point over every repository above, highest priority first
resource "google_artifact_registry_repository" "virtual" {
  location      = local.location
  project       = local.project
  repository_id = var.name
  description   = var.description
  format        = "DOCKER"
  mode          = "VIRTUAL_REPOSITORY"
  labels        = local.labels
  virtual_repository_config {
    dynamic "upstream_policies" {
      for_each = local.upstreams
      content {
        id         = upstream_policies.key
        repository = upstream_policies.value.id
        priority   = upstream_policies.value.priority
      }
    }
  }
}

resource "google_artifact_registry_repository_iam_member" "virtual" {
  for_each = merge([
    for role, members in var.iam_roles : {
      for member in members : "${role}-${member}" => { role = role, member = member }
    }
  ]...)
  project    = local.project
  location   = local.location
  repository = google_artifact_registry_repository.virtual.name
  role       = each.value.role
  member     = each.value.member
}

resource "google_artifact_registry_repository_iam_member" "standard" {
  for_each = var.standard_repository != null ? merge([
    for role, members in var.standard_repository.iam_roles : {
      for member in members : "${role}-${member}" => { role = role, member = member }
    }
  ]...) : {}
  project    = local.project
  location   = local.location
  repository = google_artifact_registry_repository.standard[0].name
  role       = each.value.role
  member     = each.value.member
}
