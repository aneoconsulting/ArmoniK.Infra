# Redis
output "host" {
  description = "Host of Redis"
  value       = local.redis_endpoints.ip
}

output "port" {
  description = "Port of Redis"
  value       = local.redis_endpoints.port
}

output "url" {
  description = "URL of Redis"
  value       = local.redis_url
}

output "user_certificate" {
  description = "User certificates of Redis"
  value = {
    secret    = kubernetes_secret.redis_client_certificate.metadata[0].name
    data_keys = keys(kubernetes_secret.redis_client_certificate.data)
  }
}

output "user_credentials" {
  description = "User credentials of Redis"
  value = {
    secret    = kubernetes_secret.redis_user.metadata[0].name
    data_keys = keys(kubernetes_secret.redis_user.data)
  }
}

output "endpoints" {
  description = "Endpoints of redis"
  value = {
    secret    = kubernetes_secret.redis.metadata[0].name
    data_keys = keys(kubernetes_secret.redis.data)
  }
}

#new Outputs 
output "env" {
  description = "Elements to be set as environment variables"
  value = ({
    "Components__ObjectStorage"                                     = var.object_storage_adapter
    "Components__ObjectStorageAdaptorSettings__ClassName"           = var.adapter_class_name
    "Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath" = var.adapter_absolute_path
    "Redis__EndpointUrl"                                            = local.redis_url
    "Redis__Ssl"                                                    = var.ssl_option
    "Redis__ClientName"                                             = var.client_name
    "Redis__CaPath"                                                 = "${var.path}/chain.pem"
    "Redis__InstanceName"                                           = var.instance_name
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
      secret = kubernetes_secret.redis.metadata[0].name
      path   = var.path
      mode   = "0644"
    }
  }
}
