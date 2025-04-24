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
