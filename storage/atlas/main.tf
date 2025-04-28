# MongoDB Atlas resources
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

  # roles {
  #   role_name     = "enableSharding"
  #   database_name = "admin"
  # }

  scopes {
    name = var.cluster_name
    type = "CLUSTER"
  }
}

data "mongodbatlas_advanced_cluster" "akaws" {
  project_id = var.project_id
  name       = var.cluster_name
  depends_on = [mongodbatlas_privatelink_endpoint_service.pe_service]
}

resource "mongodbatlas_privatelink_endpoint" "pe" {
  project_id    = var.project_id
  provider_name = "AWS"
  region        = var.region
}

resource "mongodbatlas_privatelink_endpoint_service" "pe_service" {
  project_id          = mongodbatlas_privatelink_endpoint.pe.project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.pe.id
  endpoint_service_id = aws_vpc_endpoint.vpce.id
  provider_name       = "AWS"
}
