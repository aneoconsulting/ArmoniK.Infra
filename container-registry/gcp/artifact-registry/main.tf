data "google_client_config" "current" {}

data "google_project" "project" {}

locals {
  labels = merge(var.labels, { module = "docker-artifact-registry" })
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
