locals {
  location = (var.zone == null || var.zone == "") ? var.region : "${var.region}-${var.zone}"
}

resource "null_resource" "gcp_copy_images" {

  for_each = var.registry_images

  provisioner "local-exec" {

    command = <<-EOT
        if [ -z "$(docker images -q '${each.value.image}:${each.value.tag}')" ]
        then
          if ! docker pull ${local.location}-docker.pkg.dev/${var.project_id}/${var.registry_name}/${each.value.image}:${each.value.tag}
          then
            echo "cannot download image ${each.value.image}:${each.value.tag}"
            exit 1
          fi
        fi
        if ! docker tag ${each.value.image} ${local.location}-docker.pkg.dev/${var.project_id}/${var.registry_name}/${each.value.image}:${each.value.tag}
        then
          echo "cannot tag image ${each.value.image}:${each.value.tag} to ${local.location}-docker.pkg.dev/${var.project_id}/${var.registry_name}/${each.value.image}:${each.value.tag}"
          exit 1
        fi
        if ! docker push ${local.location}-docker.pkg.dev/${var.project_id}/${var.registry_name}/${each.value.image}:${each.value.tag}
        then
          echo "cannot push image ${local.location}-docker.pkg.dev/${var.project_id}/${var.registry_name}/${each.value.image}:${each.value.tag}"
          exit 1
        fi
      
      EOT
  }
  depends_on = [
    google_artifact_registry_repository.artifact_registry_docker
  ]
}

resource "google_artifact_registry_repository" "artifact_registry_docker" {
  location      = local.location
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
  project    = var.project_id
  location   = local.location
  repository = var.registry_name
  role       = each.key
  members    = tolist(each.value)

  depends_on = [
    google_project_service.enable_service_api,
    google_artifact_registry_repository.artifact_registry_docker
  ]
}

resource "google_project_service" "enable_service_api" {
  project                    = var.project_id
  service                    = "artifactregistry.googleapis.com"
  disable_dependent_services = true
}
