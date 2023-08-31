output "service_account" {
  description = "The service account to default running nodes as if not overridden in `node_pools`."
  value       =  module.gke.service_account
}
output "cluster_id" {
  description = "Cluster ID"
  value       = module.gke.cluster_id
}

output "name" {
  description = "Cluster name"
  value       = module.gke.name
}
output "endpoint" {
  sensitive   = true
  description = "Cluster endpoint"
  value       =  module.gke.endpoint
  
}
output "ca_certificate" {
  sensitive   = true
  description = "Cluster ca certificate (base64 encoded)"
  value       =  module.gke.ca_certificate
}
output "location" {
  description = "Cluster location (region if regional cluster, zone if zonal cluster)"
  value       =  module.gke.location
}
output "kubeconfig_path" {
  description = "value"
  value=module.gke.kubeconfig_path
}