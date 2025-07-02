resource "mongodbatlas_privatelink_endpoint" "pe" {
  project_id    = var.project_id
  provider_name = "GCP"
  region        = var.region

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      provider_name,
      region,
      id
    ]
  }
}

# GCP Private Service Connect for MongoDB Atlas
resource "google_compute_forwarding_rule" "mongodb_atlas" {
  name                  = "${local.tags["name"]}-mongodb-atlas"
  project               = local.gcp_project_id
  region                = var.region
  network               = var.network_id
  load_balancing_scheme = "INTERNAL"
  subnetwork            = var.subnetwork_id
  ip_address            = var.ip_address
  target                = mongodbatlas_privatelink_endpoint.pe.endpoint_service_name

  labels = local.tags

  depends_on = [mongodbatlas_privatelink_endpoint.pe]
}

resource "mongodbatlas_privatelink_endpoint_service" "pe_service" {
  project_id          = mongodbatlas_privatelink_endpoint.pe.project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.pe.id
  endpoint_service_id = google_compute_forwarding_rule.mongodb_atlas.id
  provider_name       = "GCP"

  depends_on = [
    mongodbatlas_privatelink_endpoint.pe,
    google_compute_forwarding_rule.mongodb_atlas
  ]
}
