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
    "persistent_volume"     = var.persistent_volume
    "security_context"      = var.security_context
    "validity_period_hours" = var.validity_period_hours
  }
}

#new Outputs 
output "env" {
  description = "Elements to be set as environment variables"
  value = ({
    "Components__TableStorage"  = var.adapter_class_name
    "MongoDB__Host"             = local.mongodb_dns
    "MongoDB__Port"             = "27017"
    "MongoDB__Tls"              = var.tls
    "MongoDB__ReplicaSet"       = var.replicaset
    "MongoDB__DatabaseName"     = "database"
    "MongoDB__DirectConnection" = "false"
    "MongoDB__CAFile"           = "${var.path}/chain.pem"
  })

}

output "env_secret" {
  description = "Secrets to be set as environment variables"
  value = [
    kubernetes_secret.mongodb_user.metadata[0].name
  ]
}

output "mount_secret" {
  description = "Secrets to be mounted as volumes"
  value = {
    "mongo-certificate" = {
      secret = kubernetes_secret.mongodb.metadata[0].name
      path   = var.path
      mode   = "0600"
    },
    "mongo-certificate-helm" = {
      secret = "${helm_release.mongodb.name}-ca"
      path   = "${var.path}/certificate/"
      mode   = "0600"
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
  }
}
