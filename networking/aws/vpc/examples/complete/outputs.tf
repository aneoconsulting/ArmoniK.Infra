output "name" {
  description = "The name of the VPC"
  value       = module.complete_vpc.name
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.complete_vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = module.complete_vpc.private_subnets_cidr_blocks
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.complete_vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = module.complete_vpc.public_subnets_cidr_blocks
}

output "cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.complete_vpc.cidr_block
}

output "id" {
  description = "The ID of the VPC"
  value       = module.complete_vpc.id
}

output "flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = module.complete_vpc.flow_log_id
}

output "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = module.complete_vpc.secondary_cidr_blocks
}

output "pod_subnets_cidr_blocks" {
  description = "List of Pods subnet CIDR blocks"
  value       = module.complete_vpc.pod_subnets_cidr_blocks
}

output "pod_subnets" {
  description = "List of IDs of Pods subnets"
  value       = module.complete_vpc.pod_subnets
}
