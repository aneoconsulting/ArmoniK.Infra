data "google_client_config" "current" {}

locals {
  labels = merge(var.labels, { module = "docker-artifact-registry" })
  #docker_images = [for key, value in var.docker_images : {for element in value : "${key}-${element.image}-${element.tag}" => { name = key, registry = element.image, tag = element.tag }}]
  docker_images = merge(values({ for key, value in var.docker_images : key => { for element in value : "${key}-${element.image}-${element.tag}" => { name = key, image = element.image, tag = element.tag } } })...)
}

/*resource "null_resource" "copy_images" {
  for_each = var.docker_images
  triggers = {
    state = join("-", [each.key, each.value.image, each.value.tag])
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
if ! docker tag ${each.value.image}:${each.value.tag} ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${each.key}:${each.value.tag}
then
  echo "cannot tag image ${each.value.image}:${each.value.tag} to ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${each.key}:${each.value.tag}"
  exit 1
fi
if ! docker push ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${each.key}:${each.value.tag}
then
  echo "cannot push image ${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${each.key}:${each.value.tag}"
  exit 1
fi
EOT
  }
}*/

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
  repository = google_artifact_registry_repository.docker.name
  role       = each.key
  members    = each.value
}
