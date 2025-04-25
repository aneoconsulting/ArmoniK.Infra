# Resources for generating random credentials
resource "random_string" "mongodb_admin_user" {
  length  = 8
  special = false
  numeric = false
}

resource "random_password" "mongodb_admin_password" {
  length  = 16
  special = false
}

# MongoDB Atlas resources
resource "mongodbatlas_database_user" "admin" {
  username           = random_string.mongodb_admin_user.result
  password           = random_password.mongodb_admin_password.result
  project_id         = var.atlas_project_id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "database"
  }

  roles {
    role_name     = "readWrite"
    database_name = "admin"
  }

  # roles {
  #   role_name     = "enableSharding"
  #   database_name = "admin"
  # }

  scopes {
    name = var.atlas_cluster_name
    type = "CLUSTER"
  }
}

data "mongodbatlas_advanced_cluster" "akaws" {
  project_id = var.atlas_project_id
  name       = var.atlas_cluster_name
  depends_on = [mongodbatlas_privatelink_endpoint_service.pe_service]
}

## Private endpoint creation
resource "mongodbatlas_privatelink_endpoint" "pe" {
  project_id    = var.atlas_project_id
  provider_name = "AWS"
  region        = var.region
}

resource "mongodbatlas_privatelink_endpoint_service" "pe_service" {
  project_id          = mongodbatlas_privatelink_endpoint.pe.project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.pe.id
  endpoint_service_id = var.vpce_mongodb_atlas_endpoint_id
  provider_name       = "AWS"
  # depends_on is implicit via var.vpce_mongodb_atlas_endpoint_id referencing the VPC endpoint module output
}