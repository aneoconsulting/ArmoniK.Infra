output "reserved_service_range_id" {
  description = "The ID of the reserved service range."
  value       = google_compute_global_address.reserved_service_range.id
}

output "reserved_service_range_self_link" {
  description = "The URI of of the reserved service range."
  value       = google_compute_global_address.reserved_service_range.self_link
}

output "private_service_access" {
  description = " The PSA."
  value       = google_service_networking_connection.private_service_connection
}

output "private_service_access_peering" {
  description = " The name of the VPC Network Peering connection that was created by the service producer."
  value       = google_service_networking_connection.private_service_connection.peering
}
