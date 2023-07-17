resource "null_resource" "gcp_copy_images" {

  for_each = var.registryImages

  provisioner "local-exec" {

    command = <<-EOT
        if [ -z "$(docker images -q '${each.value.image}:${each.value.tag}')" ]
        then
          if ! docker pull ${local.location}-docker.pkg.dev/${var.project_id}/${var.registryName}/${each.value.image}:${each.value.tag}
          then
            echo "cannot download image ${each.value.image}:${each.value.tag}"
            exit 1
          fi
        fi
        if ! docker tag ${each.value.image} ${local.location}-docker.pkg.dev/${var.project_id}/${var.registryName}/${each.value.image}:${each.value.tag}
        then
          echo "cannot tag image ${each.value.image}:${each.value.tag} to ${local.location}-docker.pkg.dev/${var.project_id}/${var.registryName}/${each.value.image}:${each.value.tag}"
          exit 1
        fi
        if ! docker push ${local.location}-docker.pkg.dev/${var.project_id}/${var.registryName}/${each.value.image}:${each.value.tag}
        then
          echo "cannot push image ${local.location}-docker.pkg.dev/${var.project_id}/${var.registryName}/${each.value.image}:${each.value.tag}"
          exit 1
        fi
      
      EOT
  }
  depends_on = [
    google_artifact_registry_repository.artifact_registry_creation
  ]
}

resource "google_artifact_registry_repository" "artifact_registry_creation" {
  location      = local.location
  repository_id = var.registryName
  description   = var.registryDescription
  format        = var.registryFormat
  kms_key_name  = var.kms_key
  labels        = var.registryLabels
}

