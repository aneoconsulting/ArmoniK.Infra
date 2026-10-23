output "name" {
  description = "The name of the VPC"
  value       = module.simple_vpc.name
}

output "id" {
  description = "The VPC"
  value       = module.simple_vpc.id
}

output "subnets" {
  description = "Map of subnets"
  value       = module.simple_vpc.subnets
}
