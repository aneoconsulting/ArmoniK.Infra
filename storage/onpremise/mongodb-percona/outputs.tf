output "host" {
  description = "Hostname or IP address of MongoDB server"
  value       = local.mongodb_dns
}

output "port" {
  description = "Port of MongoDB server"
  value       = local.mongodb_port
}

output "url" {
  description = "URL of MongoDB server"
  value       = local.mongodb_url
}

output "number_of_replicas" {
  description = "Number of replicas in the MongoDB replica set"
  value       = var.cluster.replicas
}

output "env" {
  description = "Elements to be set as environment variables"
  value = merge({
    "Components__TableStorage" = "ArmoniK.Adapters.MongoDB.TableStorage"
    "MongoDB__Tls"             = "true"
    "MongoDB__CAFile"          = "/mongodb/certs/ca.crt"
    "MongoDB__DatabaseName"    = var.cluster.database_name
    }, var.sharding != null && var.sharding.enabled ? {
    "MongoDB__Sharding"   = "true"
    "MongoDB__ReplicaSet" = ""
    } : {
    "MongoDB__Sharding"   = "false"
    "MongoDB__ReplicaSet" = "rs0"
  })
  depends_on = [kubectl_manifest.cluster]
}

output "user_credentials" {
  description = "User credentials of MongoDB"
  value = {
    secret    = local.secrets_name
    data_keys = ["MONGODB_DATABASE_ADMIN_USER", "MONGODB_DATABASE_ADMIN_PASSWORD"]
  }
}

output "endpoints" {
  description = "Endpoints of MongoDB"
  value = {
    secret    = local.secrets_name
    data_keys = ["MONGODB_DATABASE_ADMIN_USER", "MONGODB_DATABASE_ADMIN_PASSWORD"]
  }
}

output "mount_secret" {
  description = "Secrets to be mounted as volumes"
  value = {
    "mongo-certificate" = {
      secret = local.ssl_secret_name
      path   = "/mongodb/certs/"
      mode   = "0644"
    }
  }
}

output "env_from_secret" {
  description = "Environment variables from secrets"
  value = {
    "MongoDB__User" = {
      secret = local.secrets_name
      field  = "MONGODB_DATABASE_ADMIN_USER"
    }
    "MongoDB__Password" = {
      secret = "${local.cluster_release_name}-secrets"
      field  = "MONGODB_DATABASE_ADMIN_PASSWORD"
    }
    "MongoDB__ConnectionString" = {
      secret = kubernetes_secret.mongodb_connection_string.metadata[0].name
      field  = "uri"
    }
    "MongoDB__MonitoringConnectionString" = {
      secret = kubernetes_secret.mongodb_monitoring_connection_string.metadata[0].name
      field  = "uri"
    }
  }
}

# Local client CA file
resource "local_sensitive_file" "mongodb_client_certificate" {
  count           = var.tls.self_managed ? 1 : 0
  content         = tls_self_signed_cert.ca[0].cert_pem
  filename        = "${path.root}/generated/certificates/${var.name}/ca.crt"
  file_permission = "0600"
}
