locals {
  pod_subnets                    = can(coalesce(var.gke_name)) ? var.pod_subnets : []
  public_subnets                 = var.enable_external_access ? var.public_subnets : []
}

# VPC
resource "google_compute_network" "vpc" {
  name                            = var.name
  project                         = var.project
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  routing_mode                    = "GLOBAL"
}

# Private subnets
resource "google_compute_subnetwork" "private_subnets" {
  count                            = length(var.private_subnets)

  name                             = "${var.name}-private-subnet-${count.index}"
  project                          = var.project
  region                           = var.region
  network                          = google_compute_network.vpc.name
  ip_cidr_range                    = var.private_subnets[count.index]
  private_ip_google_access = var.enable_google_access

  log_config {
    aggregation_interval = var.flow_log_max_aggregation_interval
    flow_sampling        = 1
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Pod subnets
resource "google_compute_subnetwork" "pod_subnets" {
  count                            = length(local.pod_subnets)

  name                             = "${var.name}-pod-subnet-${count.index}"
  project                          = var.project
  region                           = var.region
  network                          = google_compute_network.vpc.name
  ip_cidr_range                    = var.pod_subnets[count.index]
  private_ip_google_access = var.enable_google_access

  log_config {
    aggregation_interval = var.flow_log_max_aggregation_interval
    flow_sampling        = 1
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Public subnets
resource "google_compute_subnetwork" "public_subnets" {
  count                            = length(local.public_subnets)

  name                             = "${var.name}-public-subnet-${count.index}"
  project                          = var.project
  region                           = var.region
  network                          = google_compute_network.vpc.id
  ip_cidr_range                    = local.public_subnets[count.index]
  private_ip_google_access = var.enable_google_access

  log_config {
    aggregation_interval = var.flow_log_max_aggregation_interval
    flow_sampling        = 1
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# External access for public subnets
resource "google_compute_router" "router" {
  count   = var.enable_external_access ? 1 : 0

  name    = "${var.name}-router"
  project = var.project
  network = google_compute_network.vpc.self_link
  region  = var.region
}

resource "google_compute_router_nat" "nat_gateway" {
  count                              = var.enable_external_access ? 1 : 0

  name                               = "${var.name}-nat"
  project                            = var.project
  router                             = google_compute_router.router[count.index].name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = google_compute_subnetwork.public_subnets
    content {
      name                     = subnetwork.value.name
      source_ip_ranges_to_nat  = ["PRIMARY_IP_RANGE"]
    }
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}