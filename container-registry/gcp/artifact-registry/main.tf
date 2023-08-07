data "google_client_config" "current" {}

locals {
labels = merge(var.labels, { module = "docker-artifact-registry" }) 
}

resource "null_resource" "gcp_copy_images" {

  for_each = var.docker_images

  provisioner "local-exec" {

    command = <<-EOT
        if [ -z "$(docker images -q '${each.value.image}:${each.value.tag}')" ]
        then
          if ! docker pull ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${each.value.image}:${each.value.tag}
          then
            echo "cannot download image ${each.value.image}:${each.value.tag}"
            exit 1
          fi
        fi
        if ! docker tag ${each.value.image} ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${each.value.image}:${each.value.tag}
        then
          echo "cannot tag image ${each.value.image}:${each.value.tag} to ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${each.value.image}:${each.value.tag}"
          exit 1
        fi
        if ! docker push ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${each.value.image}:${each.value.tag}
        then
          echo "cannot push image ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${each.value.image}:${each.value.tag}"
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
  kms_key_name  = var.kms_key_name
  labels        = local.labels
  mode          = "STANDARD_REPOSITORY"
  docker_config {
    immutable_tags = var.immutable_tags
  }
}

resource "google_artifact_registry_repository_iam_binding" "binding" {
  for_each   = var.iam_bindings
  project    = data.google_client_config.current.project
  location   = data.google_client_config.current.region
  repository = var.name
  role       = each.key
  members    = each.value
}
