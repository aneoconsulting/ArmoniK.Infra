resource "random_string" "mongodb_admin_user" {
  length  = 8
  special = false
  numeric = false
}

resource "random_password" "mongodb_admin_password" {
  length  = 16
  special = false
}

resource "random_string" "mongodb_application_user" {
  length  = 8
  special = false
  numeric = false
}

resource "random_password" "mongodb_application_password" {
  length  = 16
  special = false
}

resource "random_string" "mongodb_monitoring_user" {
  length  = 8
  special = false
  numeric = false
}

resource "random_password" "mongodb_monitoring_password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "mongodb_admin" {
  metadata {
    name      = "mongodb-admin"
    namespace = var.namespace
  }
  data = {
    username = random_string.mongodb_admin_user.result
    password = random_password.mongodb_admin_password.result
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "mongodb_user" {
  metadata {
    name      = "mongodb-user"
    namespace = var.namespace
  }
  data = {
    username = random_string.mongodb_application_user.result
    password = random_password.mongodb_application_password.result
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "mongodb_monitoring_connection_string" {
  metadata {
    name      = "mongodb-monitoring-connection-string"
    namespace = var.namespace
  }
  data = {
    uri = "mongodb://${random_string.mongodb_monitoring_user.result}:${random_password.mongodb_monitoring_password.result}@${local.mongodb_dns}:27017/admin?tls=true&tlsAllowInvalidCertificates=true&tlsAllowInvalidHostnames=true&tlsCAFile=/mongodb/certificate/mongodb-ca-cert&authSource=admin"
  }
}
