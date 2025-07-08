output "host" {
  description = "Hostname or IP address of MongoDB server"
  value       = local.mongodb_dns
}

output "port" {
  description = "Port of MongoDB server"
  value       = 27017
}

output "url" {
  description = "URL of MongoDB server"
  value       = local.mongodb_url
}

output "number_of_replicas" {
  description = "Number of replicas of MongoDB"
  value       = var.mongodb.replicas
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

# Uses the unused variables that are defined to pass the CI pre-commit check
output "unused_variables" {
  description = "Map of variables that are not used yet but might be in the future"
  value = {
    "validity_period_hours" = var.validity_period_hours
  }
}

#new Outputs 
output "env" {
  description = "Elements to be set as environment variables"
  value = ({
    "Components__TableStorage"  = "ArmoniK.Adapters.MongoDB.TableStorage"
    "MongoDB__Host"             = local.mongodb_dns
    "MongoDB__Port"             = "27017"
    "MongoDB__Tls"              = "true"
    "MongoDB__ReplicaSet"       = "rs0"
    "MongoDB__DatabaseName"     = "database"
    "MongoDB__DirectConnection" = "false"
    "MongoDB__CAFile"           = "/mongodb/certificate/mongodb-ca-cert"
    "MongoDB__AuthSource"       = "database"
  })

}

output "mount_secret" {
  description = "Secrets to be mounted as volumes"
  value = {
    "mongo-certificate" = {
      secret = kubernetes_secret.mongodb.metadata[0].name
      path   = "/mongodb/certs/"
      mode   = "0644"
    },
    "mongo-certificate-helm" = {
      secret = "${helm_release.mongodb.name}-ca"
      path   = "/mongodb/certificate/"
      mode   = "0644"
    }
  }
}

output "env_from_secret" {
  description = "Environment variables from secrets"
  value = {
    "MongoDB__User" = {
      secret = kubernetes_secret.mongodb_user.metadata[0].name
      field  = "username"
    },
    "MongoDB__Password" = {
      secret = kubernetes_secret.mongodb_user.metadata[0].name
      field  = "password"
    }
    "MongoDB__MonitoringConnectionString" = {
      secret = kubernetes_secret.mongodb_monitoring_connection_string.metadata[0].name
      field  = "uri"
    }
  }
}
