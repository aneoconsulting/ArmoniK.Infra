output "artifact_registry" {
    description = "Registry created on GCP" 
    value       = module.simple_artifact_registry.artifact_registry #"Registry url : https://console.cloud.google.com/artifacts/docker/${var.project_id}/${module.simple_artifact_registry.artifact_registry}/${var.registry_name}/"
}

output "kms_key" {
    description = "KMS used for registry"
    value       = module.simple_artifact_registry.kms_key
}