data "google_client_config" "current" {}

resource "null_resource" "gcp_copy_images" {

  for_each = var.registry_images

  provisioner "local-exec" {

    command = <<-EOT
        if [ -z "$(docker images -q '${each.value.image}:${each.value.tag}')" ]
        then
          if ! docker pull ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${var.registry_name}/${each.value.image}:${each.value.tag}
          then
            echo "cannot download image ${each.value.image}:${each.value.tag}"
            exit 1
          fi
        fi
        if ! docker tag ${each.value.image} ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${var.registry_name}/${each.value.image}:${each.value.tag}
        then
          echo "cannot tag image ${each.value.image}:${each.value.tag} to ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${var.registry_name}/${each.value.image}:${each.value.tag}"
          exit 1
        fi
        if ! docker push ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${var.registry_name}/${each.value.image}:${each.value.tag}
        then
          echo "cannot push image ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${var.registry_name}/${each.value.image}:${each.value.tag}"
          exit 1
        fi
      
      EOT
  }
  depends_on = [
    google_artifact_registry_repository.artifact_registry_docker
  ]
}

resource "google_artifact_registry_repository" "artifact_registry_docker" {
  location      = data.google_client_config.current.region
  repository_id = var.registry_name
  description   = var.registry_description
  format        = "docker"
  kms_key_name  = var.kms_key
  labels        = var.registry_labels
  docker_config {
    immutable_tags = var.immutable_tags
  }

  depends_on = [
    google_project_service.enable_service_api
  ]
}

resource "google_artifact_registry_repository_iam_binding" "binding" {
  for_each   = var.registry_iam != null ? var.registry_iam : {}
  project    = data.google_client_config.current.project
  location   = data.google_client_config.current.region
  repository = var.registry_name
  role       = each.key
  members    = tolist(each.value)

  depends_on = [
    google_project_service.enable_service_api,
    google_artifact_registry_repository.artifact_registry_docker
  ]
}

resource "google_project_service" "enable_service_api" {
  project                    = data.google_client_config.current.project
  service                    = "artifactregistry.googleapis.com"
  disable_dependent_services = true
}
