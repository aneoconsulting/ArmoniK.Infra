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

output "gke_subnets" {
  description = "Map of GKE subnets"
  value = {
    for key in keys(module.complete_vpc.gke_subnet_ids) : key => {
      id                = module.complete_vpc.gke_subnet_ids[key],
      cidr_block        = module.complete_vpc.gke_subnet_cidr_blocks[key],
      self_link         = module.complete_vpc.gke_subnet_self_links[key],
      pod_range_name    = module.complete_vpc.gke_subnet_pod_ranges[key].range_name,
      pod_ip_cidr_range = module.complete_vpc.gke_subnet_pod_ranges[key].ip_cidr_range,
      svc_range_name    = module.complete_vpc.gke_subnet_svc_ranges[key].range_name,
      svc_ip_cidr_range = module.complete_vpc.gke_subnet_svc_ranges[key].ip_cidr_range
    }
  }
}
