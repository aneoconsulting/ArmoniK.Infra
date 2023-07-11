provider "google" {
    project = var.project_id
}

resource "google_artifact_registry_repository" "my-repo" {
  count = length(var.repositories)
  location = var.repositories[count.index].location
  repository_id = var.repositories[count.index].repository_id
  description = var.repositories[count.index].description
  format = var.repositories[count.index].format
  kms_key_name = var.kms_key_id