output "peering_network" {
    description = "The VPC that the PSA will use"
    value       = module.complete_example.peering_network
}

output "private_ip_alloc" {
    description = "The IP address reserved for the VPC"
    value       = module.complete_example.private_ip_alloc
}

output "private_service_access" {
    description = "The PSA"
    value       = module.complete_example.private_service_access
}