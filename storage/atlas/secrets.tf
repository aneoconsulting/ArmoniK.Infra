
# Create Kubernetes secrets for MongoDB access
resource "kubernetes_secret" "mongodb_admin" {
  metadata {
    name      = "mongodb-atlas-admin"
    namespace = var.namespace
  }
  data = {
    username = random_string.mongodb_admin_user.result
    password = random_password.mongodb_admin_password.result
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "mongodbatlas_connection_string" {
  metadata {
    name      = "mongodbatlas-connection-string"
    namespace = var.namespace
  }
  data = {
    string = "mongodb+srv://${random_string.mongodb_admin_user.result}:${random_password.mongodb_admin_password.result}@${local.mongodb_url.dns}/database"
  }
}

resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "mongodb-atlas"
    namespace = var.namespace
  }
  data = {
    username = random_string.mongodb_admin_user.result
    password = random_password.mongodb_admin_password.result
  }
}
