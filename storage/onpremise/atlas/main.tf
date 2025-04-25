# Environment variables "MONGODB_ATLAS_PUBLIC_KEY" and "MONGODB_ATLAS_PRIVATE_KEY" must be 
# set and exported for the provider to access your MongoDB Atlas cluster

provider "mongodbatlas" {
  public_key  = var.mongodb_atlas_public_key
  private_key = var.mongodb_atlas_private_key
}

# Ensure certificate is downloaded before creating users
resource "null_resource" "certificate_dependency" {
  depends_on = [
    null_resource.download_atlas_certificate
  ]

  # Only create this resource if we're supposed to download the certificate
  count = var.download_atlas_certificate ? 1 : 0
}

resource "mongodbatlas_database_user" "admin" {
  username           = random_string.mongodb_admin_user.result
  password           = random_password.mongodb_admin_password.result
  project_id         = var.atlas.project_id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = local.mongodb_database_name
  }

  roles {
    role_name     = "readWrite"
    database_name = "admin"
  }

  scopes {
    name = var.atlas.cluster_name
    type = "CLUSTER"
  }

  # If certificate download is enabled, depend on the certificate being downloaded
  depends_on = [
    null_resource.certificate_dependency
  ]
}

data "mongodbatlas_advanced_cluster" "aklocal" {
  project_id = var.atlas.project_id
  name       = var.atlas.cluster_name
  depends_on = [mongodbatlas_database_user.admin]
}

# Private endpoint creation - only created if AWS integration is enabled
resource "mongodbatlas_privatelink_endpoint" "pe" {
  count         = var.enable_private_endpoint ? 1 : 0
  project_id    = var.atlas.project_id
  provider_name = "AWS"
  region        = var.aws_region
}

# Connect MongoDB Atlas to the AWS VPC endpoint
resource "mongodbatlas_privatelink_endpoint_service" "pe_service" {
  count               = var.enable_private_endpoint && var.aws_endpoint_id != "" ? 1 : 0
  project_id          = mongodbatlas_privatelink_endpoint.pe[0].project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.pe[0].id
  endpoint_service_id = var.aws_endpoint_id
  provider_name       = "AWS"
  
  # Make sure the private endpoint exists before trying to connect to it
  depends_on = [mongodbatlas_privatelink_endpoint.pe]
}

# If using AWS private endpoints, get the connection info
locals {
  # Get private endpoints if they exist
  private_endpoints = var.enable_private_endpoint && var.aws_endpoint_id != "" ? flatten([
      for cs in try(data.mongodbatlas_advanced_cluster.aklocal.connection_strings, []) : 
      try(cs.private_endpoint, [])
    ]) : []
  
  # Extract the SRV connection strings that match our endpoint ID
  connection_strings = var.enable_private_endpoint && var.aws_endpoint_id != "" ? [
    for pe in local.private_endpoints : pe.srv_connection_string
    if contains([for e in try(pe.endpoints, []) : e.endpoint_id], var.aws_endpoint_id)
  ] : []
  
  # Use the first connection string if available
  private_connection_string = length(local.connection_strings) > 0 ? local.connection_strings[0] : ""
}