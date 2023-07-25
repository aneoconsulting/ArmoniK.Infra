output "region" {
  description = "Region used for the subnets"
  value       = var.region
}

output "name" {
  description = "The name of the VPC"
  value       = module.complete_vpc.name
}

output "private_subnets" {
  description = "List of private subnets"
  value       = module.complete_vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnets"
  value       = module.complete_vpc.public_subnets
}

output "pod_subnets" {
  description = "List of Pods subnets"
  value       = module.complete_vpc.pod_subnets
}

output "id" {
  description = "The VPC"
  value       = module.complete_vpc.id
}
