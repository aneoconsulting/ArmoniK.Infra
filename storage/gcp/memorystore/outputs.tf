output "id" {
  description = "The memorystore instance ID."
  value       = google_redis_instance.default.id
}

output "host" {
  description = "The IP address of the instance."
  value       = google_redis_instance.default.host
}

output "port" {
  description = "The port number of the exposed Redis endpoint."
  value       = google_redis_instance.default.port
}

output "read_endpoint" {
  description = " The IP address of the exposed readonly Redis endpoint."
  value       = google_redis_instance.default.read_endpoint
}

output "region" {
  description = "The region the instance lives in."
  value       = google_redis_instance.default.region
}

output "current_location_id" {
  description = "The current zone where the Redis endpoint is placed."
  value       = google_redis_instance.default.current_location_id
}

output "persistence_iam_identity" {
  description = "Cloud IAM identity used by import/export operations. Format is 'serviceAccount:'. May change over time"
  value       = google_redis_instance.default.persistence_iam_identity
}

output "auth_string" {
  description = "AUTH String set on the instance. This field will only be populated if auth_enabled is true."
  value       = google_redis_instance.default.auth_string
  sensitive   = true
}

output "server_ca_certs" {
  description = "List of server CA certificates for the instance"
  value       = google_redis_instance.default.server_ca_certs
  sensitive   = false
}

############# SECTION - PROJECT SERVICE

output "project_id" {
  description = "The GCP project you want to enable APIs on"
  value       = element(concat([for v in google_project_service.project_services : v.project], [var.project]), 0)
}

output "enabled_apis" {
  description = "Enabled APIs in the project"
  value       = [for api in google_project_service.project_services : api.service]
}

output "enabled_api_identities" {
  description = "Enabled API identities in the project"
  value       = { for i in google_project_service_identity.project_service_identities : i.service => i.email }
}