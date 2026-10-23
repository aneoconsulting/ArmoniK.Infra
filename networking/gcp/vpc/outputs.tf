output "name" {
  description = "The name of the VPC"
  value       = google_compute_network.vpc.name
}

output "id" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "gateway_ipv4" {
  description = "The gateway address for default routing out of the network. This value is selected by GCP"
  value       = google_compute_network.vpc.gateway_ipv4
}

output "self_link" {
  description = "The URI of the created resource"
  value       = google_compute_network.vpc.self_link
}

output "subnets" {
  description = "Map of the subnets, keyed by name, with their ID, CIDR block, self link, region and whether their outbound traffic goes through Cloud NAT"
  value = {
    for key, subnet in google_compute_subnetwork.subnets : key => {
      id         = subnet.id
      cidr_block = subnet.ip_cidr_range
      self_link  = subnet.self_link
      region     = subnet.region
      enable_nat = var.subnets[key].enable_nat
    }
  }
}

output "gke_subnet_name" {
  description = "GKE subnet name"
  value       = try(google_compute_subnetwork.gke_subnet[0].name, null)
}

output "gke_subnet_region" {
  description = "GKE subnet region"
  value       = try(google_compute_subnetwork.gke_subnet[0].region, null)
}

output "gke_subnet_id" {
  description = "GKE subnet ID"
  value       = try(google_compute_subnetwork.gke_subnet[0].id, null)
}

output "gke_subnet_cidr_block" {
  description = "GKE subnet CIDR block"
  value       = try(google_compute_subnetwork.gke_subnet[0].ip_cidr_range, null)
}

output "gke_subnet_self_link" {
  description = "GKE subnet self link"
  value       = try(google_compute_subnetwork.gke_subnet[0].self_link, null)
}

output "gke_subnet_pods_cidr_block" {
  description = "IP CIDR block of GKE Pods"
  value       = try(google_compute_subnetwork.gke_subnet[0].secondary_ip_range[0].ip_cidr_range, null)
}

output "gke_subnet_pods_range_name" {
  description = "IP CIDR range name of GKE Pods"
  value       = try(google_compute_subnetwork.gke_subnet[0].secondary_ip_range[0].range_name, null)
}

output "gke_subnet_svc_cidr_block" {
  description = "IP CIDR block of GKE services"
  value       = try(google_compute_subnetwork.gke_subnet[0].secondary_ip_range[1].ip_cidr_range, null)
}

output "gke_subnet_svc_range_name" {
  description = "IP CIDR range name of GKE services"
  value       = try(google_compute_subnetwork.gke_subnet[0].secondary_ip_range[1].range_name, null)
}
