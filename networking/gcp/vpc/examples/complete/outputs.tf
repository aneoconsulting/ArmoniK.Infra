output "name" {
  description = "The name of the VPC"
  value       = module.complete_vpc.name
}

output "id" {
  description = "The VPC"
  value       = module.complete_vpc.id
}

output "subnets" {
  description = "Map of subnets"
  value       = module.complete_vpc.subnets
}

output "gke_subnet" {
  description = "GKE subnet"
  value = {
    name                = module.complete_vpc.gke_subnet_name
    self_link           = module.complete_vpc.gke_subnet_self_link
    nodes_cidr_block    = module.complete_vpc.gke_subnet_cidr_block
    pods_range_name     = module.complete_vpc.gke_subnet_pods_range_name
    pods_cidr_block     = module.complete_vpc.gke_subnet_pods_cidr_block
    services_range_name = module.complete_vpc.gke_subnet_svc_range_name
    services_cidr_block = module.complete_vpc.gke_subnet_svc_cidr_block
    region              = module.complete_vpc.gke_subnet_region
  }
}

output "service_connection_policies" {
  description = "Service connection policies"
  value       = module.complete_vpc.service_connection_policies
}
