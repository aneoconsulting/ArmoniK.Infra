output "private_ip_alloc" {
  description = "The IP address reserved for the VPC"
  value       = module.simple_example.private_ip_alloc
}

output "private_service_access" {
  description = "The PSA"
  value       = module.simple_example.private_service_access
}
