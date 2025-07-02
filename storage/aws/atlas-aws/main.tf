resource "mongodbatlas_database_user" "admin" {
  username           = random_string.mongodb_admin_user.result
  password           = random_password.mongodb_admin_password.result
  project_id         = var.project_id
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
    name = var.cluster_name
    type = "CLUSTER"
  }
}

data "mongodbatlas_advanced_cluster" "atlas" {
  project_id = var.project_id
  name       = var.cluster_name
  depends_on = [mongodbatlas_privatelink_endpoint_service.pe_service]
}
