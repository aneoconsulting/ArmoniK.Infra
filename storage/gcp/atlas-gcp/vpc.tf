# TODO: Complete the configuration for MongoDB Atlas PrivateLink endpoints in GCP
# Stuck in the target process and how to bind the correct value.

locals {
  # Generate a random ID to ensure uniqueness for resources
  random_suffix = random_id.suffix.hex

  # Define endpoint name pattern
  base_endpoint_name = coalesce(var.override_endpoint_name, "${var.namespace}-${var.cluster_name}-mongodb-atlas")

  # Generate address list with nulls as placeholders if needed
  addresses = concat(
    coalesce(var.addresses, []),
    [for _ in range(coalesce(var.nb_psc, 1)) : null]
  )

  # Number of PSC endpoints to create
  psc_count = coalesce(var.nb_psc, 1)
}

# Generate random suffix for unique naming
resource "random_id" "suffix" {
  byte_length = 6

  # Add keepers to make the random ID stable unless these values change
  keepers = {
    project_id = var.project_id
    region     = var.region
  }
}

# Create the Atlas PrivateLink endpoint
resource "mongodbatlas_privatelink_endpoint" "pe" {
  project_id    = var.project_id
  provider_name = "GCP"
  region        = var.region

  lifecycle {
    create_before_destroy = true
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }
}

# Fetch the Atlas PrivateLink service name
data "mongodbatlas_privatelink_endpoint" "pe_data" {
  project_id      = var.project_id
  private_link_id = mongodbatlas_privatelink_endpoint.pe.id
  provider_name   = "GCP"

  depends_on = [mongodbatlas_privatelink_endpoint.pe]
}

# Create IP addresses for each PSC endpoint
resource "google_compute_address" "psc_ip_addresses" {
  count        = local.psc_count
  name         = "${local.base_endpoint_name}-${count.index}-${local.random_suffix}"
  region       = var.region
  project      = local.gcp_project_id
  subnetwork   = var.gke_subnet
  address_type = "INTERNAL"
  address      = local.addresses[count.index]

  lifecycle {
    create_before_destroy = true
  }
}

# Create forwarding rules for each PSC endpoint
resource "google_compute_forwarding_rule" "mongodb_atlas" {
  count                 = local.psc_count
  name                  = "${local.base_endpoint_name}-${count.index}-${local.random_suffix}"
  project               = local.gcp_project_id
  region                = var.region
  network               = var.vpc_network
  subnetwork            = var.gke_subnet
  load_balancing_scheme = ""
  ip_address            = google_compute_address.psc_ip_addresses[count.index].address

  target                  = data.mongodbatlas_privatelink_endpoint.pe_data.endpoint_service_name
  all_ports               = true
  labels                  = local.tags
  allow_psc_global_access = true

  depends_on = [data.mongodbatlas_privatelink_endpoint.pe_data]

  lifecycle {
    precondition {
      condition     = length(data.mongodbatlas_privatelink_endpoint.pe_data.endpoint_service_name) > 0
      error_message = "MongoDB Atlas service attachment name is not available. Ensure the Atlas PrivateLink endpoint is created and available."
    }
  }
}
# Link GCP forwarding rules to MongoDB Atlas
resource "mongodbatlas_privatelink_endpoint_service" "pe_service" {
  project_id      = var.project_id
  private_link_id = mongodbatlas_privatelink_endpoint.pe.id
  provider_name   = "GCP"
  gcp_project_id  = local.gcp_project_id

  # Use the first forwarding rule as the endpoint service ID
  endpoint_service_id = google_compute_forwarding_rule.mongodb_atlas[0].name

  # Dynamically create endpoints for each forwarding rule
  dynamic "endpoints" {
    for_each = google_compute_forwarding_rule.mongodb_atlas
    content {
      endpoint_name = endpoints.value.name
      ip_address    = endpoints.value.ip_address
    }
  }

  depends_on = [
    mongodbatlas_privatelink_endpoint.pe,
    google_compute_forwarding_rule.mongodb_atlas
  ]

  timeouts {
    create = "30m"
    delete = "30m"
  }

  lifecycle {
    ignore_changes = [
      project_id,
      private_link_id,
      endpoints
    ]
  }
}
