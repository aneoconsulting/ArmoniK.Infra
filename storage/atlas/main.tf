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


resource "mongodbatlas_privatelink_endpoint" "pe" {
  project_id    = var.atlas.project_id
  provider_name = "AWS"
  region        = var.region
}



data "mongodbatlas_advanced_cluster" "akaws" {
  project_id = var.atlas.project_id
  name       = var.atlas.cluster_name
}

resource "mongodbatlas_privatelink_endpoint_service" "pe_service" {
  project_id          = var.atlas.project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.pe.private_link_id
  endpoint_service_id = local.effective_endpoint_id
  provider_name       = "AWS"

  depends_on = [aws_vpc_endpoint.mongodb_atlas]
}

resource "null_resource" "wait_for_privatelink" {
  depends_on = [mongodbatlas_privatelink_endpoint_service.pe_service]

  triggers = {
    pe_service_id          = mongodbatlas_privatelink_endpoint_service.pe_service.id
    private_link_id        = mongodbatlas_privatelink_endpoint.pe.private_link_id
    connection_string_sha1 = sha1(local.connection_string)
  }
}
