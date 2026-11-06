output "id" {
  description = "ID of the instance"
  value       = google_memorystore_instance.valkey.id
}

output "host" {
  description = "IP address of the primary endpoint"
  value       = local.primary.ip_address
}

output "port" {
  description = "Port of the primary endpoint"
  value       = local.primary.port
}

output "url" {
  description = "Address of the primary endpoint, as host:port (Redis__EndpointUrl of Core)"
  value       = local.url
}

output "reader_url" {
  description = "Address of the reader endpoint, as host:port, which spreads reads over the replicas. Null without replicas"
  value       = try("${local.endpoints["CONNECTION_TYPE_READER"].ip_address}:${local.endpoints["CONNECTION_TYPE_READER"].port}", null)
}

output "ca_certificates" {
  description = "PEM certificates of the CA that signs the server certificate (Redis__CaPath of Core). Null without TLS"
  value       = local.tls ? local.ca_certificates : null
}

output "env" {
  description = "Elements to be set as environment variables"
  value = {
    "Components__ObjectStorageAdaptorSettings__ClassName"           = var.adapter_class_name
    "Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath" = var.adapter_absolute_path
    "Redis__EndpointUrl"                                            = local.url
    "Redis__Ssl"                                                    = coalesce(var.ssl_option, tostring(local.tls))
    "Redis__ClientName"                                             = var.client_name
    "Redis__InstanceName"                                           = var.instance_name
    "Redis__CaPath"                                                 = "/redis/chain.pem"
  }
}

output "mount_secret" {
  description = "Secrets to be mounted as volumes"
  value = {
    "redis-secret1" = {
      secret = kubernetes_secret.redis_ca.metadata[0].name
      path   = "/redis"
      mode   = "0644"
    }
  }
}
