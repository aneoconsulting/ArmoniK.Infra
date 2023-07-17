resource "null_resource" "gcp_copy_images" {

  for_each = {
    for image in local.repository_images : "${image.repository_name}.${image.image_name}" => image
  }

  provisioner "local-exec" {

    command = <<-EOT
        if [ -z "$(docker images -q '${each.value.image_name}:${each.value.image_tag}')" ]
        then
          if ! docker pull ${local.location}-docker.pkg.dev/${var.project_id}/${each.value.repository_name}/${each.value.image_name}:${each.value.image_tag}
          then
            echo "cannot download image ${each.value.image_name}:${each.value.image_tag}"
            exit 1
          fi
        fi
        if ! docker tag ${each.value.image_name} ${local.location}-docker.pkg.dev/${var.project_id}/${each.value.repository_name}/${each.value.image_name}:${each.value.image_tag}
        then
          echo "cannot tag image ${each.value.image_name}:${each.value.image_tag} to ${local.location}-docker.pkg.dev/${var.project_id}/${each.value.repository_name}/${each.value.image_name}:${each.value.image_tag}"
          exit 1
        fi
        if ! docker push ${local.location}-docker.pkg.dev/${var.project_id}/${each.value.repository_name}/${each.value.image_name}:${each.value.image_tag}
        then
          echo "cannot push image ${local.location}-docker.pkg.dev/${var.project_id}/${each.value.repository_name}/${each.value.image_name}:${each.value.image_tag}"
          exit 1
        fi
      
      EOT
  }
  depends_on = [
    google_artifact_registry_repository.artifact_registry_creation
  ]
}

resource "google_artifact_registry_repository" "artifact_registry_creation" {
  count         = length(var.repositories)
  location      = local.location
  repository_id = var.repositories[count.index].artifact_repository_name
  description   = var.repositories[count.index].description
  format        = var.repositories[count.index].format
}

