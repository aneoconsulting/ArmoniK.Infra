output "peering_network" {
    description = "The VPC that the PSA will use"
    value       = data.google_compute_network.peering_network
}

output "private_ip_alloc" {
    description = "The IP address reserved for the VPC"
    value       = google_compute_global_address.private_ip_alloc
}

output "private_service_access" {
    description = "The PSA"
    value       = google_service_networking_connection.private_service_access
}