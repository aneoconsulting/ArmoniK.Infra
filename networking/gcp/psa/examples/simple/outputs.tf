output "private_ip_alloc" {
  description = "The IP address reserved for the VPC"
  value       = module.simple.reserved_service_range_self_link
}

output "private_service_access" {
  description = "The PSA"
  value       = module.simple.private_service_access_peering
}
