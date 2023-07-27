# Configuration in the current provider
data "google_client_config" "current" {}

locals {
  enable_external_access = length(var.public_subnets) > 0
}

# VPC
resource "google_compute_network" "vpc" {
  name                                      = var.name
  description                               = "VPC deployment of name ${var.name}"
  auto_create_subnetworks                   = var.auto_create_subnetworks
  routing_mode                              = var.routing_mode
  mtu                                       = var.mtu
  enable_ula_internal_ipv6                  = var.enable_ula_internal_ipv6
  internal_ipv6_range                       = can(coalesce(var.enable_ula_internal_ipv6)) ? var.internal_ipv6_range : null
  network_firewall_policy_enforcement_order = var.network_firewall_policy_enforcement_order
  project                                   = data.google_client_config.current.project
  delete_default_routes_on_create           = var.delete_default_routes_on_create
}

# Shared VPC host project
resource "google_compute_shared_vpc_host_project" "shared" {
  count      = var.shared_vpc_host_project ? 1 : 0
  project    = data.google_client_config.current.project
  depends_on = [google_compute_network.vpc]
}

# Private subnets
resource "google_compute_subnetwork" "private_subnets" {
  for_each                 = var.private_subnets
  ip_cidr_range            = each.key
  name                     = "${google_compute_network.vpc.name}-private-${replace(each.key, "/\\W/", "-")}"
  network                  = google_compute_network.vpc.name
  description              = "Private subnet of IP address range ${each.key} in VPC ${google_compute_network.vpc.name}"
  purpose                  = "PRIVATE_RFC_1918"
  private_ip_google_access = var.enable_google_access
  region                   = data.google_client_config.current.region
  project                  = data.google_client_config.current.project
  log_config {
    aggregation_interval = var.flow_log_max_aggregation_interval
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Public subnets
resource "google_compute_subnetwork" "public_subnets" {
  for_each                 = var.public_subnets
  ip_cidr_range            = each.key
  name                     = "${google_compute_network.vpc.name}-public-${replace(each.key, "/\\W/", "-")}"
  network                  = google_compute_network.vpc.name
  description              = "Public subnet of IP address range ${each.key} in VPC ${google_compute_network.vpc.name}"
  purpose                  = "PRIVATE_RFC_1918"
  private_ip_google_access = var.enable_google_access
  region                   = data.google_client_config.current.region
  project                  = data.google_client_config.current.project
  log_config {
    aggregation_interval = var.flow_log_max_aggregation_interval
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# GKE private subnets
resource "google_compute_subnetwork" "gke_subnets" {
  for_each                 = var.gke_subnets
  ip_cidr_range            = each.value.nodes_cidr_block
  name                     = each.key
  network                  = google_compute_network.vpc.name
  description              = "GKE private subnet of IP address range ${each.value.nodes_cidr_block} in VPC ${google_compute_network.vpc.name}"
  purpose                  = "PRIVATE_RFC_1918"
  private_ip_google_access = var.enable_google_access
  region                   = data.google_client_config.current.region
  project                  = data.google_client_config.current.project
  log_config {
    aggregation_interval = var.flow_log_max_aggregation_interval
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
  }
  dynamic "secondary_ip_range" {
    for_each = ["pods_cidr_block", "services_cidr_block"]
    content {
      ip_cidr_range = each.value[secondary_ip_range.key]
      range_name    = secondary_ip_range.key == "pods_cidr_block" ? "${each.key}-pod-ranges" : "${each.key}-svc-ranges"
    }
  }
}

# External access for public subnets
resource "google_compute_router" "router" {
  count       = local.enable_external_access ? 1 : 0
  name        = "${google_compute_network.vpc.name}-router"
  network     = google_compute_network.vpc.self_link
  description = "Router in the VPC ${google_compute_network.vpc.name}"
  region      = data.google_client_config.current.region
  project     = data.google_client_config.current.project
}

resource "google_compute_router_nat" "nat_gateway" {
  for_each                           = length(google_compute_router.router) > 0 ? [1] : []
  name                               = "${google_compute_network.vpc.name}-nat"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  router                             = one(google_compute_router.router[*].name)
  region                             = data.google_client_config.current.region
  project                            = data.google_client_config.current.project
  dynamic "subnetwork" {
    for_each = google_compute_subnetwork.public_subnets
    content {
      name                    = subnetwork.value.name
      source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
    }
  }
  log_config {
    enable = true
    filter = "ALL"
  }
}
