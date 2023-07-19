output "artifact_registry" {
  description = "Registry created on GCP"
  value       = "Registry url : https://console.cloud.google.com/artifacts/docker/${var.project_id}/${local.location}/${var.registry_name}/"
}

output "kms_key" {
  description = "KMS used for registry"
  value       = var.kms_key
}
