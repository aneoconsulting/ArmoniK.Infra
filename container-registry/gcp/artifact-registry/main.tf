data "google_client_config" "current" {}

data "google_project" "project" {}

locals {
  labels              = merge(var.labels, { module = "docker-artifact-registry" })
  registry_host       = "${data.google_client_config.current.region}-docker.pkg.dev"
  remote_repositories = try(var.pull_through_cache.remote_repositories, {})
  virtual_iam_roles = {
    for binding in flatten([
      for role, members in try(var.pull_through_cache.iam_roles, {}) : [
        for member in members : { role = role, member = member }
      ]
    ]) : "${binding.role}.${binding.member}" => binding
  }
  docker_images = merge(values({
    for key, value in var.docker_images : key => {
      for element in value : "${key}-${element.image}-${element.tag}" => {
        name = key, image = element.image, tag = element.tag
      }
    }
  })...)
}

resource "google_project_service_identity" "kms" {
  count    = can(coalesce(var.kms_key_id)) ? 1 : 0
  provider = google-beta
  project  = data.google_client_config.current.project
  service  = "artifactregistry.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "kms" {
  count         = can(coalesce(var.kms_key_id)) ? 1 : 0
  crypto_key_id = var.kms_key_id
  member        = "serviceAccount:${google_project_service_identity.kms[0].email}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

resource "null_resource" "copy_images" {
  for_each = local.docker_images
  triggers = {
    state = each.key
  }
  provisioner "local-exec" {
    command = <<-EOT
gcloud auth configure-docker ${data.google_client_config.current.region}-docker.pkg.dev
if [ -z "$(docker images -q '${each.value.image}:${each.value.tag}')" ]
then
  if ! docker pull ${each.value.image}:${each.value.tag}
  then
    echo "cannot download image ${each.value.image}:${each.value.tag}"
    exit 1
  fi
fi
if ! docker tag ${each.value.image}:${each.value.tag} ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${each.value.name}:${each.value.tag}
then
  echo "cannot tag image ${each.value.image}:${each.value.tag} to ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${each.value.name}:${each.value.tag}"
  exit 1
fi
if ! docker push ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${each.value.name}:${each.value.tag}
then
  echo "cannot push image ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${each.value.name}:${each.value.tag}"
  exit 1
fi
EOT
  }
}

resource "google_artifact_registry_repository" "docker" {
  location      = data.google_client_config.current.region
  project       = data.google_client_config.current.project
  repository_id = var.name
  description   = var.description
  format        = "docker"
  kms_key_name  = var.kms_key_id
  labels        = local.labels
  mode          = "STANDARD_REPOSITORY"
  docker_config {
    immutable_tags = var.immutable_tags
  }
  depends_on = [google_kms_crypto_key_iam_member.kms]
}

resource "google_artifact_registry_repository_iam_member" "artifact_registry_roles" {
  for_each = {
    for role in flatten([
      for role_key, role in var.iam_roles : [
        for member in role : {
          role = role_key, member = member
        }
      ]
    ]) : "${role.role}.${role.member}" => role
  }
  project    = data.google_client_config.current.project
  location   = data.google_client_config.current.region
  repository = google_artifact_registry_repository.docker.name
  role       = each.value.role
  member     = each.value.member
}

# Pull-through caches of the public registries
resource "google_artifact_registry_repository" "remote" {
  for_each      = local.remote_repositories
  location      = data.google_client_config.current.region
  project       = data.google_client_config.current.project
  repository_id = "${var.name}-${each.key}"
  description   = coalesce(each.value.description, "Pull-through cache of ${coalesce(each.value.uri, each.value.public_repository)}")
  format        = "docker"
  kms_key_name  = var.kms_key_id
  labels        = local.labels
  mode          = "REMOTE_REPOSITORY"
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
  depends_on = [google_kms_crypto_key_iam_member.kms]
}

# Single entry point over the registry above and the pull-through caches, highest priority first
resource "google_artifact_registry_repository" "virtual" {
  count         = var.pull_through_cache != null ? 1 : 0
  location      = data.google_client_config.current.region
  project       = data.google_client_config.current.project
  repository_id = "${var.name}-virtual"
  description   = "Images of ${var.name} and of its pull-through caches"
  format        = "docker"
  labels        = local.labels
  mode          = "VIRTUAL_REPOSITORY"
  virtual_repository_config {
    upstream_policies {
      id         = "standard"
      repository = google_artifact_registry_repository.docker.id
      priority   = var.pull_through_cache.standard_priority
    }
    dynamic "upstream_policies" {
      for_each = google_artifact_registry_repository.remote
      content {
        id         = upstream_policies.key
        repository = upstream_policies.value.id
        priority   = local.remote_repositories[upstream_policies.key].priority
      }
    }
  }
}

resource "google_artifact_registry_repository_iam_member" "virtual" {
  for_each   = local.virtual_iam_roles
  project    = data.google_client_config.current.project
  location   = data.google_client_config.current.region
  repository = google_artifact_registry_repository.virtual[0].name
  role       = each.value.role
  member     = each.value.member
}
