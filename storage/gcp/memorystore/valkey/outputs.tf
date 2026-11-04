output "id" {
  description = "ID of the instance"
  value       = google_memorystore_instance.valkey.id
}

output "host" {
  description = "IP address of the primary endpoint"
  value       = local.endpoints["CONNECTION_TYPE_PRIMARY"].ip_address
}

output "port" {
  description = "Port of the primary endpoint"
  value       = local.endpoints["CONNECTION_TYPE_PRIMARY"].port
}

output "url" {
  description = "Address of the primary endpoint, as host:port (Redis__EndpointUrl of Core)"
  value       = "${local.endpoints["CONNECTION_TYPE_PRIMARY"].ip_address}:${local.endpoints["CONNECTION_TYPE_PRIMARY"].port}"
}

output "reader_url" {
  description = "Address of the reader endpoint, as host:port, which spreads reads over the replicas. Null without replicas"
  value       = try("${local.endpoints["CONNECTION_TYPE_READER"].ip_address}:${local.endpoints["CONNECTION_TYPE_READER"].port}", null)
}

output "ca_certificates" {
  description = "PEM certificates of the CA that signs the server certificate (Redis__CaPath of Core). Null without TLS"
  value       = try(join("\n", flatten(google_memorystore_instance.valkey.managed_server_ca[0].ca_certs[*].certificates)), null)
}
