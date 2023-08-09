output "name" {
  description = "The name of the VPC"
  value       = module.complete_vpc.name
}

output "id" {
  description = "The VPC"
  value       = module.complete_vpc.id
}

output "private_subnets" {
  description = "Map of private subnets"
  value = {
    for key in keys(module.complete_vpc.private_subnet_ids) : key => {
      id         = module.complete_vpc.private_subnet_ids[key],
      cidr_block = module.complete_vpc.private_subnet_cidr_blocks[key],
      self_link  = module.complete_vpc.private_subnet_self_links[key]
      region     = module.complete_vpc.private_subnet_regions[key]
    }
  }
}

output "public_subnets" {
  description = "Map of public subnets"
  value = {
    for key in keys(module.complete_vpc.public_subnet_ids) : key => {
      id         = module.complete_vpc.public_subnet_ids[key],
      cidr_block = module.complete_vpc.public_subnet_cidr_blocks[key],
      self_link  = module.complete_vpc.public_subnet_self_links[key]
      region     = module.complete_vpc.public_subnet_regions[key]
    }
  }
}

output "gke_subnet" {
  description = "GKE subnet"
  value = {
    name                = module.vpc.gke_subnet_name,
    nodes_cidr_block    = module.vpc.gke_subnet_cidr_block
    pods_range_name     = module.vpc.gke_subnet_pods_range_name
    pods_cidr_block     = module.vpc.gke_subnet_pods_cidr_block
    services_range_name = module.vpc.gke_subnet_svc_range_name
    services_cidr_block = module.vpc.gke_subnet_svc_cidr_block
    region              = module.vpc.gke_subnet_region
  }
}
