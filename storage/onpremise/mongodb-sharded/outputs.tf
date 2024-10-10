output "host" {
  description = "Hostname or IP address of MongoDB server"
  value       = local.mongodb_dns
}

output "port" {
  description = "Port of MongoDB server"
  value       = var.mongodb.service_port
}

output "url" {
  description = "URL of MongoDB server"
  value       = local.mongodb_url
}

output "number_of_replicas" {
  description = "Number of replicas for each shard"
  value       = var.sharding.shards.replicas
}

output "number_of_shards" {
  description = "Number of MongoDB shards"
  value       = var.sharding.shards
}

output "user_credentials" {
  description = "User credentials of MongoDB"
  value = {
    secret    = kubernetes_secret.mongodb_user.metadata[0].name
    data_keys = keys(kubernetes_secret.mongodb_user.data)
  }
}

output "endpoints" {
  description = "Endpoints of MongoDB"
  value = {
    secret    = kubernetes_secret.mongodb.metadata[0].name
    data_keys = keys(kubernetes_secret.mongodb.data)
  }
}

#new Outputs 
output "env" {
  description = "Elements to be set as environment variables"
  value = ({
    "Components__TableStorage"  = "ArmoniK.Adapters.MongoDB.TableStorage"
    "MongoDB__Host"             = local.mongodb_dns
    "MongoDB__Port"             = var.mongodb.service_port
    "MongoDB__Tls"              = "true"
    "MongoDB__ReplicaSet"       = "rs0"
    "MongoDB__DatabaseName"     = "database"
    "MongoDB__DirectConnection" = "true"
    "MongoDB__CAFile"           = "/mongodb/certs/chain.pem"
    "MongoDB__Sharding"         = "true"
    "MongoDB__AuthSource"       = "admin"
  })
}

output "mount_secret" {
  description = "Secrets to be mounted as volumes"
  value = {
    "mongo-certificate" = {
      secret = kubernetes_secret.mongodb.metadata[0].name
      path   = "/mongodb/certs/"
      mode   = "0644"
    }
  }
}

output "env_from_secret" {
  description = "Environment variables from secrets"
  value = {
    "MongoDB__User" = {
      secret = kubernetes_secret.mongodb_admin.metadata[0].name
      field  = "MONGO_USERNAME"
    },
    "MongoDB__Password" = {
      secret = kubernetes_secret.mongodb_admin.metadata[0].name
      field  = "MONGO_PASSWORD"
    }
  }
}
