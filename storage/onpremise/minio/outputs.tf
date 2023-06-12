output "host" {
  description = "Host of MinIO"
  value       = var.minio.host
}

output "port" {
  description = "Port of MinIO"
  value       = local.port
}

output "url" {
  description = "URL of MinIO"
  value       = "http://${var.minio.host}:${local.port}"
}

output "console_url" {
  description = "Web YRL of MinIO"
  value       = "http://${var.minio.host}:${local.console_port}"
}

output "login" {
  description = "Username of MinIO"
  value       = random_string.minio_application_user.result
  sensitive   = true
}

output "password" {
  description = "Password of MinIO"
  value       = random_password.minio_application_password.result
  sensitive   = true
}

output "bucket_name" {
  description = "Name of the MinIO bucket"
  value       = var.minio.bucket_name
}

output "must_force_path_style" {
  description = "Boolean to force path style"
  # needed for dns resolution on prem http://bucket.servicename:8001 vs http://servicename:8001/bucket
  value = true
}
