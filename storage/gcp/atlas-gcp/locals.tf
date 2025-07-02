# Get current GCP project if not explicitly provided
data "google_client_config" "current" {}

locals {
  # Use provided project ID or fall back to current project
  gcp_project_id = coalesce(var.gcp_project_id, data.google_client_config.current.project)

  private_endpoints = flatten([for cs in data.mongodbatlas_advanced_cluster.atlas.connection_strings : cs.private_endpoint])

  connection_strings = [
    for pe in local.private_endpoints : pe.srv_connection_string
    if contains([for e in pe.endpoints : e.endpoint_id], google_compute_forwarding_rule.mongodb_atlas.id)
  ]

  # GCP-compliant tags (lowercase, no special characters, max 63 chars)
  gcp_tags = {
    for k, v in var.tags :
    substr(lower(replace(replace(k, "/[^a-zA-Z0-9_-]/", "-"), "/^[^a-z]/", "a")), 0, 63) =>
    substr(lower(replace(v, "/[^a-zA-Z0-9_-]/", "-")), 0, 63)
  }

  tags = merge(
    local.gcp_tags,
    {
      name       = "${var.namespace}-${var.cluster_name}-mongodb-atlas"
      namespace  = var.namespace
      cluster    = var.cluster_name
      service    = "mongodb-atlas"
      managed_by = "terraform"
    }
  )

  connection_string = length(local.connection_strings) > 0 ? local.connection_strings[0] : ""
  mongodb_url       = regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<dns>[^/?#]*))", local.connection_string)
}
