output "auth_string" {
  description = "AUTH String set on the instance. This field will only be populated if auth_enabled is true."
  value       = google_redis_instance.cache.auth_string
  sensitive   = true
}

output "id" {
  description = "The Memorystore instance ID."
  value       = google_redis_instance.cache.id
}

output "current_location_id" {
  description = "The current zone where the Redis endpoint is placed."
  value       = google_redis_instance.cache.current_location_id
}

output "host" {
  description = "The IP address of the instance."
  value       = google_redis_instance.cache.host
}

output "port" {
  description = "The port number of the exposed Redis endpoint."
  value       = google_redis_instance.cache.port
}

output "url" {
  description = "The URL of the exposed Redis endpoint."
  value       = "${google_redis_instance.cache.host}:${google_redis_instance.cache.port}"
}

output "persistence_iam_identity" {
  description = "Cloud IAM identity used by import/export operations. Format is 'serviceAccount:'. May change over time"
  value       = google_redis_instance.cache.persistence_iam_identity
}

output "server_ca_certs" {
  description = "List of server CA certificates for the instance"
  value       = google_redis_instance.cache.server_ca_certs
  sensitive   = true
}

output "nodes" {
  description = "Info per node. The parameters are: \"id\" and \"zone\"."
  value       = google_redis_instance.cache.nodes
}

output "read_endpoint" {
  description = "The IP address of the exposed readonly Redis endpoint."
  value       = google_redis_instance.cache.read_endpoint
}

output "read_endpoint_port" {
  description = "The port number of the exposed readonly Redis endpoint. Standard tier only. Write requests should target 'port'."
  value       = google_redis_instance.cache.read_endpoint_port
}

output "read_endpoint_url" {
  description = "The URL of the exposed readonly Redis endpoint."
  value       = "${google_redis_instance.cache.read_endpoint}:${google_redis_instance.cache.read_endpoint_port}"
}

output "region" {
  description = "The region the instance lives in."
  value       = google_redis_instance.cache.region
}

#new Outputs 
output "env" {
  description = "Elements to be set as environment variables"
  value = ({
    "Components__ObjectStorage"                                     = var.object_storage_adapter
    "Components__ObjectStorageAdaptorSettings__ClassName"           = var.adapter_class_name
    "Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath" = var.adapter_absolute_path
    "Redis__EndpointUrl"                                            = "${google_redis_instance.cache.host}:${google_redis_instance.cache.port}"
    "Redis__Ssl"                                                    = var.ssl_option
    "Redis__ClientName"                                             = var.client_name
    "Redis__InstanceName"                                           = var.instance_name
    "Redis__CaPath"                                                 = "${var.path}/chain.pem"
  })
}

output "env_secret" {
  description = "Secrets to be set as environment variables"
  value = [
    kubernetes_secret.redis_user_credentials.metadata[0].name
  ]
}

output "mount_secret" {
  description = "Secrets to be mounted as volumes"
  value = {
    "redis-secret1" = {
      secret = kubernetes_secret.redis_ca.metadata[0].name
      path   = var.path
      mode   = "0644"
    }
  }
}
