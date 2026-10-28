# Configuration in the current provider
data "google_client_config" "current" {}

locals {
  nat_subnets    = { for key, value in var.subnets : key => value if value.enable_nat }
  gke_subnet_nat = try(var.gke_subnet.enable_nat, false)
  nat_regions = toset(concat(
    [for key, value in local.nat_subnets : value.region],
    local.gke_subnet_nat ? [var.gke_subnet.region] : []
  ))
  subnet_ids = merge(
    { for key, subnet in google_compute_subnetwork.subnets : key => subnet.id },
    { for subnet in google_compute_subnetwork.gke_subnet : subnet.name => subnet.id }
  )
  subnet_regions = merge(
    { for key, value in var.subnets : key => value.region },
    var.gke_subnet != null ? { (var.gke_subnet.name) = var.gke_subnet.region } : {}
  )
}

# VPC
resource "google_compute_network" "vpc" {
  name                                      = var.name
  description                               = "VPC deployment of name ${var.name}"
  auto_create_subnetworks                   = var.auto_create_subnetworks
  routing_mode                              = var.routing_mode
  mtu                                       = var.mtu
  enable_ula_internal_ipv6                  = var.enable_ula_internal_ipv6
  internal_ipv6_range                       = var.internal_ipv6_range
  network_firewall_policy_enforcement_order = var.network_firewall_policy_enforcement_order
  project                                   = data.google_client_config.current.project
  delete_default_routes_on_create           = var.delete_default_routes_on_create
}

# Subnets
resource "google_compute_subnetwork" "subnets" {
  for_each                 = var.subnets
  ip_cidr_range            = each.value.cidr_block
  name                     = each.key
  network                  = google_compute_network.vpc.name
  description              = "Subnet of IP address range ${each.value.cidr_block} in VPC ${google_compute_network.vpc.name}"
  private_ip_google_access = var.enable_google_access
  region                   = each.value.region
  project                  = data.google_client_config.current.project
  log_config {
    aggregation_interval = var.flow_log_max_aggregation_interval
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# GKE subnet
resource "google_compute_subnetwork" "gke_subnet" {
  count                    = var.gke_subnet != null ? 1 : 0
  ip_cidr_range            = var.gke_subnet.nodes_cidr_block
  name                     = var.gke_subnet.name
  network                  = google_compute_network.vpc.name
  description              = "GKE subnet of IP address range ${var.gke_subnet.nodes_cidr_block} in VPC ${google_compute_network.vpc.name}"
  private_ip_google_access = var.enable_google_access
  region                   = var.gke_subnet.region
  project                  = data.google_client_config.current.project
  log_config {
    aggregation_interval = var.flow_log_max_aggregation_interval
    flow_sampling        = "1.0"
    metadata             = "INCLUDE_ALL_METADATA"
  }
  dynamic "secondary_ip_range" {
    for_each = ["pods_cidr_block", "services_cidr_block"]
    content {
      ip_cidr_range = var.gke_subnet[secondary_ip_range.value]
      range_name    = secondary_ip_range.value == "pods_cidr_block" ? "${var.gke_subnet.name}-pod-ranges" : "${var.gke_subnet.name}-svc-ranges"
    }
  }
}

# Outbound internet access through Cloud NAT
# Router
resource "google_compute_router" "routers" {
  for_each    = local.nat_regions
  name        = "${google_compute_network.vpc.name}-router-${each.value}"
  network     = google_compute_network.vpc.self_link
  description = "Router for the VPC ${google_compute_network.vpc.name} in region ${each.key}"
  region      = each.value
  project     = data.google_client_config.current.project
}

# NAT gateway
resource "google_compute_router_nat" "nat_gateway" {
  for_each                           = local.nat_regions
  name                               = "${google_compute_network.vpc.name}-nat-${each.value}"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  router                             = google_compute_router.routers[each.key].name
  region                             = each.value
  project                            = data.google_client_config.current.project
  dynamic "subnetwork" {
    for_each = [for key, value in local.nat_subnets : key if value.region == each.value]
    content {
      name                    = google_compute_subnetwork.subnets[subnetwork.value].id
      source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
    }
  }
  # Secondary ranges included: Pod traffic keeps its Pod IP when default SNAT is disabled on the cluster
  dynamic "subnetwork" {
    for_each = [for subnet in google_compute_subnetwork.gke_subnet : subnet.id if local.gke_subnet_nat && subnet.region == each.value]
    content {
      name                    = subnetwork.value
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
  log_config {
    enable = true
    filter = "ALL"
  }
}

# Private Service Connect: Google services of a class create their endpoints in these subnets
resource "google_network_connectivity_service_connection_policy" "policies" {
  for_each      = var.service_connection_policies
  name          = "${google_compute_network.vpc.name}-${each.key}"
  location      = local.subnet_regions[each.value.subnets[0]]
  service_class = each.value.service_class
  network       = google_compute_network.vpc.id
  description   = "Private Service Connect endpoints of ${each.value.service_class} in VPC ${google_compute_network.vpc.name}"
  project       = data.google_client_config.current.project
  psc_config {
    subnetworks = [for subnet in each.value.subnets : local.subnet_ids[subnet]]
    limit       = each.value.limit != null ? tostring(each.value.limit) : null
  }
}
