output "mongodb" {
  description = "JSON representation of the Helm chart's MongoDB deployment metadata"
  value       = helm_release.mongodb.metadata[0]
}

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
  value       = var.mongodb.replicas_number
}

output "user_certificate" {
  description = "User certificates of MongoDB"
  value = {
    secret    = data.kubernetes_secret.mongodb_certificates.metadata[0].name
    data_keys = keys(data.kubernetes_secret.mongodb_certificates.binary_data)
  }
  depends_on = [helm_release.mongodb]
  sensitive  = true
}

output "user_credentials" {
  description = "User credentials of MongoDB"
  value = {
    secret    = data.kubernetes_secret.mongodb_credentials.metadata[0]
    data_keys = keys(data.kubernetes_secret.mongodb_credentials.binary_data)
  }
  depends_on = [helm_release.mongodb]
  sensitive  = true
}

/*

output "endpoints" {
  description = "Endpoints of MongoDB"
  value = {
    secret    = kubernetes_secret.mongodb.metadata[0].name
    data_keys = keys(kubernetes_secret.mongodb.data)
  }
}
*/
