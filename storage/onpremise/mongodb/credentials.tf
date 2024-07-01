/*resource "random_string" "mongodb_admin_user" {
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
*/

data "kubernetes_secret" "mongodb_credentials" {
  metadata {
    name = var.name
    namespace = var.namespace
  }
  depends_on = [ helm_release.mongodb ]
}

resource "kubernetes_secret" "mongodb_admin" {
  metadata {
    name      = "mongodb-admin"
    namespace = var.namespace
  }
  data = {
    username = "root"
    password = data.kubernetes_secret.mongodb_credentials.data["mongodb-root-password"]
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "mongodb_user" {
  metadata {
    name      = "mongodb-user"
    namespace = var.namespace
  }
  data = {
    username = "root"
    password = data.kubernetes_secret.mongodb_credentials.data["mongodb-root-password"]
  }
  type = "kubernetes.io/basic-auth"
}
