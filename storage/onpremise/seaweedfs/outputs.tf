output "host" {
  description = "Host of the SeaweedFS S3 service"
  value       = local.host
  # Known at plan time: makes the Core wait for the release, bucket creation hook included
  depends_on = [helm_release.seaweedfs]
}

output "port" {
  description = "Port of the SeaweedFS S3 service"
  value       = local.port
  # Known at plan time: makes the Core wait for the release, bucket creation hook included
  depends_on = [helm_release.seaweedfs]
}

output "url" {
  description = "URL of the SeaweedFS S3 service"
  value       = local.url
  # Known at plan time: makes the Core wait for the release, bucket creation hook included
  depends_on = [helm_release.seaweedfs]
}

output "console_url" {
  description = "URL of the SeaweedFS filer web UI"
  value       = "http://${local.host}:${local.console_port}"
  # Known at plan time: makes the Core wait for the release, bucket creation hook included
  depends_on = [helm_release.seaweedfs]
}

output "login" {
  description = "S3 access key of SeaweedFS"
  value       = random_string.access_key.result
  sensitive   = true
}

output "password" {
  description = "S3 secret key of SeaweedFS"
  value       = random_password.secret_key.result
  sensitive   = true
}

output "bucket_name" {
  description = "Name of the SeaweedFS bucket"
  value       = var.bucket_name
  # Known at plan time: makes its readers wait for the release, bucket creation hook included
  depends_on = [helm_release.seaweedfs]
}

output "must_force_path_style" {
  description = "Boolean to force path style"
  value       = local.must_force_path_style
}

output "env" {
  description = "Elements to be set as environment variables"
  value = {
    "Components__ObjectStorageAdaptorSettings__ClassName"           = var.adapter_class_name
    "Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath" = var.adapter_absolute_path
    "S3__BucketName"                                                = var.bucket_name
    "S3__UseChecksum"                                               = local.use_checksum
    "S3__MustForcePathStyle"                                        = local.must_force_path_style
    "S3__UseChunkEncoding"                                          = local.use_chunk_encoding
    "S3__EndpointUrl"                                               = local.url
  }
  # Known at plan time: makes the Core wait for the release, bucket creation hook included
  depends_on = [helm_release.seaweedfs]
}

output "env_from_secret" {
  description = "Environment variables from secrets"
  value = {
    "S3__Login" = {
      secret = kubernetes_secret_v1.s3.metadata[0].name
      field  = "username"
    }
    "S3__Password" = {
      secret = kubernetes_secret_v1.s3.metadata[0].name
      field  = "password"
    }
  }
}
