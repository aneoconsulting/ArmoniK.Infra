resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.namespace
  }
  data = {
    username   = random_string.mongodb_application_user.result
    password   = random_password.mongodb_application_password.result
  }
}

resource "kubernetes_secret" "mongodbatlas_connection_string" {
  metadata {
    name      = "mongodb-connection-string"
    namespace = var.namespace
  }
  data = {
    string = local.private_connection_string != "" ? local.private_connection_string : local.public_connection_string
  }
}
