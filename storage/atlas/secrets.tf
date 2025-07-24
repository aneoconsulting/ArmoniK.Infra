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
    string = "mongodb+srv://${random_string.mongodb_admin_user.result}:${random_password.mongodb_admin_password.result}@${local.mongodb_url.dns}/database"
  }
}

resource "kubernetes_secret" "mongodbatlas_monitoring_connection_string" {
  metadata {
    name      = "mongodb-monitoring-connection-string"
    namespace = var.namespace
  }
  data = {
    uri = "mongodb+srv://${random_string.mongodb_monitoring_user.result}:${random_password.mongodb_monitoring_password.result}@${local.mongodb_url.dns}/admin"
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
