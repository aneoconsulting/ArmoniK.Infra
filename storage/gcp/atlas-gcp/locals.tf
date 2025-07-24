# Get current GCP project if not explicitly provided
data "google_client_config" "current" {}

locals {
  # Use provided GCP project ID or get current from provider
  gcp_project_id = coalesce(var.gcp_project_id, data.google_client_config.current.project)

  # Add standard tags for resources
  tags = merge(
    var.tags,
    {
      name       = "${var.namespace}-${var.cluster_name}"
      project    = var.project_id
      managed-by = "terraform"
      component  = "mongodb-atlas"
    }
  )

  # Add the connection string local value
  connection_string = try(
    data.mongodbatlas_advanced_cluster.atlas.connection_strings[0].private_endpoint[0].srv_connection_string,
    ""
  )
}
