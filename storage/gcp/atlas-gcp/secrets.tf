resource "random_string" "mongodb_admin_user" {
  length  = 8
  special = false
  numeric = false
  upper   = false
}

resource "random_password" "mongodb_admin_password" {
  length  = 16
  special = true
}

resource "kubernetes_secret" "mongodb_admin" {
  metadata {
    name      = "${var.cluster_name}-mongodb-admin"
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
    name      = "${var.cluster_name}-mongodbatlas-connection-string"
    namespace = var.namespace
  }
  data = {
    string = local.connection_string
  }
}

resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "${var.cluster_name}-mongodb"
    namespace = var.namespace
  }
  data = {
    username = random_string.mongodb_admin_user.result
    password = random_password.mongodb_admin_password.result
  }
}
