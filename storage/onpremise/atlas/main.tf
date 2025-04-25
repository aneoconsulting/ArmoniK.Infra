# Environment variables "MONGODB_ATLAS_PUBLIC_KEY" and "MONGODB_ATLAS_PRIVATE_KEY" must be 
# set and exported for the provider to access your MongoDB Atlas cluster

# Core MongoDB Atlas resources
resource "mongodbatlas_database_user" "admin" {
  username           = random_string.mongodb_admin_user.result
  password           = random_password.mongodb_admin_password.result
  project_id         = var.atlas.project_id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "database"
  }

  roles {
    role_name     = "readWrite"
    database_name = "admin"
  }

  scopes {
    name = var.atlas.cluster_name
    type = "CLUSTER"
  }
}

data "mongodbatlas_advanced_cluster" "aklocal" {
  project_id = var.atlas.project_id
  name       = var.atlas.cluster_name
  depends_on = [mongodbatlas_database_user.admin]
}

# Add the second data source for when using private endpoints
data "mongodbatlas_advanced_cluster" "akaws" {
  count      = var.enable_private_endpoint && var.aws_endpoint_id != "" ? 1 : 0
  project_id = var.atlas.project_id
  name       = var.atlas.cluster_name
  depends_on = [mongodbatlas_privatelink_endpoint_service.pe_service]
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
  
  depends_on = [mongodbatlas_privatelink_endpoint.pe]
}