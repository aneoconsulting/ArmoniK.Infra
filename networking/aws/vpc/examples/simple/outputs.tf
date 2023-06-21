output "name" {
  description = "The name of the VPC"
  value       = module.simple_vpc.name
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.simple_vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = module.simple_vpc.private_subnets_cidr_blocks
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.simple_vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = module.simple_vpc.public_subnets_cidr_blocks
}

output "cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.simple_vpc.cidr_block
}

output "id" {
  description = "The ID of the VPC"
  value       = module.simple_vpc.id
}

output "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = module.simple_vpc.secondary_cidr_blocks
}
