output "mongodb_url" {
  description = "MongoDB URL information"
  value       = local.mongodb_url
}


output "endpoint_service_name" {
  description = "MongoDB Atlas privatelink endpoint service name"
  value       = mongodbatlas_privatelink_endpoint.pe.endpoint_service_name
}

output "env_from_secret" {
  description = "MongoDB Atlas env from secret"
  value = {
    "MongoDB__User" = {
      secret = kubernetes_secret.mongodb_admin.metadata[0].name
      field  = "username"
    }
    "MongoDB__Password" = {
      secret = kubernetes_secret.mongodb_admin.metadata[0].name
      field  = "password"
    }
    "MongoDB__ConnectionString" = {
      secret = kubernetes_secret.mongodbatlas_connection_string.metadata[0].name
      field  = "string"
    }
    "MongoDB__MonitoringConnectionString" = {
      secret = kubernetes_secret.mongodbatlas_monitoring_connection_string.metadata[0].name
      field  = "uri"
    }
  }
}

output "env" {
  description = "MongoDB Atlas env"
  value = {
    "Components__TableStorage"  = "ArmoniK.Adapters.MongoDB.TableStorage"
    "MongoDB__Host"             = local.mongodb_url.dns
    "MongoDB__Tls"              = "true"
    "MongoDB__DatabaseName"     = "database"
    "MongoDB__DirectConnection" = "false"
    "MongoDB__AuthSource"       = "admin"
    "MongoDB__Sharding"         = "false" # Depending on the sharding strategy, this may need to be set to true
  }
}
