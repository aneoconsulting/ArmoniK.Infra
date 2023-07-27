output "region" {
  description = "Region used for the subnets"
  value       = var.region
}

output "name" {
  description = "The name of the VPC"
  value       = module.simple_vpc.name
}

output "id" {
  description = "The VPC"
  value       = module.simple_vpc.id
}

output "private_subnets" {
  description = "Map of private subnets"
  value = {
    for key in keys(module.simple_vpc.private_subnet_ids) : key => {
      id         = module.simple_vpc.private_subnet_ids[key],
      cidr_block = module.simple_vpc.private_subnet_cidr_blocks[key],
      self_link  = module.simple_vpc.private_subnet_self_links[key]
    }
  }
}

output "public_subnets" {
  description = "Map of public subnets"
  value = {
    for key in keys(module.simple_vpc.public_subnet_ids) : key => {
      id         = module.simple_vpc.public_subnet_ids[key],
      cidr_block = module.simple_vpc.public_subnet_cidr_blocks[key],
      self_link  = module.simple_vpc.public_subnet_self_links[key]
    }
  }
}
