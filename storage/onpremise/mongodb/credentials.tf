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

#secret for credential to variable

resource "kubernetes_secret" "mongodb_user_credentials" {
  metadata {
    name      = "mongodb-user-credentials"
    namespace = var.namespace
  }
  data = {
    "MongoDB__User"     = random_string.mongodb_application_user.result
    "MongoDB__Password" = random_password.mongodb_application_password.result
  }
}
