data "kubernetes_secret" "mongodb_credentials" {
  metadata {
    name      = "${helm_release.mongodb.name}"
    namespace = var.namespace
  }
}

resource "kubernetes_secret" "mongodb_admin" {
  metadata {
    name      = "mongodb-admin"
    namespace = var.namespace
  }
  data = {
    username = "root"
    password = local.mongodb_root_password
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

resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.namespace
  }
  data = {
    "chain.pem"        = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_self_signed_cert.root_mongodb.cert_pem)
    username           = random_string.mongodb_application_user.result
    password           = random_password.mongodb_application_password.result
    host               = local.mongodb_dns
    port               = var.mongodb.service_port
    url                = local.mongodb_url
    number_of_replicas = var.mongodb.replicas_number
  }
}
