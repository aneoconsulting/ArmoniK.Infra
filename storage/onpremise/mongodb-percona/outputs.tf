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

# ──────────────────────────────────────────────
# Placeholder outputs for ArmoniK compatibility
# These will be properly wired up in Phase 2-4
# ──────────────────────────────────────────────

output "env" {
  description = "Elements to be set as environment variables"
  value = merge({
    "Components__TableStorage"  = "ArmoniK.Adapters.MongoDB.TableStorage"
    "MongoDB__Host"             = local.mongodb_dns
    "MongoDB__Port"             = tostring(local.mongodb_port)
    "MongoDB__Tls"              = "true" 
    "MongoDB__CAFile"           = "/mongodb/certs/ca.crt"
    "MongoDB__DatabaseName"     = var.cluster.database_name
    "MongoDB__DirectConnection" = "false"
    "MongoDB__AuthSource"       = "admin"
  }, var.sharding != null && var.sharding.enabled ? {
      "MongoDB__Sharding"  = "true"
      "MongoDB__ReplicaSet" = ""
    } : {
      "MongoDB__Sharding"   = "false"
      "MongoDB__ReplicaSet" = "rs0"
    })
}

output "user_credentials" {
  description = "User credentials of MongoDB"
  value = {
    secret    = "${local.cluster_release_name}-secrets"
    data_keys = ["MONGODB_DATABASE_ADMIN_USER", "MONGODB_DATABASE_ADMIN_PASSWORD"]
  }
}

output "endpoints" {
  description = "Endpoints of MongoDB"
  value = {
    secret    = "${local.cluster_release_name}-secrets"
    data_keys = ["MONGODB_DATABASE_ADMIN_USER", "MONGODB_DATABASE_ADMIN_PASSWORD"]
  }
}

output "mount_secret" {
  description = "Secrets to be mounted as volumes"
  value = {
    "mongo-certificate" = {
      secret = "${local.cluster_release_name}-ssl"
      path   = "/mongodb/certs/"
      mode   = "0644"
    }
  }
}

output "env_from_secret" {
  description = "Environment variables from secrets"
  value = {
    "MongoDB__User" = {
      secret = "${local.cluster_release_name}-secrets"
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
  }
}
