resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.namespace
  }
  data = {
    username   = random_string.mongodb_application_user.result
    password   = random_password.mongodb_application_password.result
    host       = local.mongodb_url.dns
    port       = local.mongodb_port
    url        = try(data.mongodbatlas_advanced_cluster.aklocal.connection_strings[0].standard_srv, "")
    tls        = "true"
    authSource = local.mongodb_auth_source
  }
}

resource "kubernetes_secret" "mongodbatlas_connection_string" {
  metadata {
    name      = "mongodb-connection-string"
    namespace = var.namespace
  }
  data = {
    string = try(data.mongodbatlas_advanced_cluster.aklocal.connection_strings[0].standard_srv, "")
  }
}
