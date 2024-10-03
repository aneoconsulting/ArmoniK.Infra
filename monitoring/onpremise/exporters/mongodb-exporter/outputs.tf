# MongoDB metrics exporter

output "url" {
  description = "Url of the MongoDB Metrics exporter"
  value       = "${kubernetes_service.mongodb_exporter_service.spec[0].cluster_ip}:${kubernetes_service.mongodb_exporter_service.spec[0].port[0].port}"
}

output "namespace" {
  description = "Namespace of the MongoDB metrics exporter"
  value       = var.namespace
}
