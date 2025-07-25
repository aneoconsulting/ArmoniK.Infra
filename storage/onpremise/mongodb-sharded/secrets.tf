data "kubernetes_secret" "mongodb_credentials" {
  metadata {
    name      = helm_release.mongodb.name
    namespace = var.namespace
  }
  depends_on = [helm_release.mongodb]
}

resource "kubernetes_secret" "mongodb_admin" {
  metadata {
    name      = "${var.name}-admin"
    namespace = var.namespace
  }
  data = {
    MONGO_USERNAME = "root"
    MONGO_PASSWORD = local.mongodb_root_password
  }
}

resource "kubernetes_secret" "mongodb_user" {
  metadata {
    name      = "${var.name}-user"
    namespace = var.namespace
  }
  data = {
    # When using Bitnami's MongoDB image, MONGODB_USERNAME and MONGODB_PASSWORD are forbidden env variables names, see https://github.com/bitnami/containers/issues/18506
    MONGO_USERNAME = random_string.mongodb_application_user.result
    MONGO_PASSWORD = random_password.mongodb_application_password.result
  }
}

resource "kubernetes_secret" "mongodb_monitoring_connection_string" {
  metadata {
    name      = "mongodb-monitoring-connection-string"
    namespace = var.namespace
  }
  data = {
    uri = "mongodb://${random_string.mongodb_monitoring_user.result}:${random_password.mongodb_monitoring_password.result}@${local.mongodb_dns}:27017/admin?tls=true&tlsAllowInvalidCertificates=true&tlsAllowInvalidHostnames=true&tlsCAFile=/mongodb/certs/ca.pem&authSource=admin"
  }
}

resource "kubernetes_secret" "mongodb_connection_string" {
  metadata {
    name      = "mongodb-connection-string"
    namespace = var.namespace
  }
  data = {
    uri = "mongodb+srv://root:${local.mongodb_root_password}@${local.mongodb_dns}/${var.mongodb.database_name}?authSource=admin"
  }
}

resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "custom-${var.name}"
    namespace = helm_release.mongodb.namespace
  }
  data = {
    "ca.pem"           = tls_self_signed_cert.root_mongodb.cert_pem
    "mongodb.pem"      = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_private_key.mongodb_private_key.private_key_pem)
    "chain.pem"        = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_self_signed_cert.root_mongodb.cert_pem)
    username           = random_string.mongodb_application_user.result
    password           = random_password.mongodb_application_password.result
    host               = local.mongodb_dns
    port               = var.mongodb.service_port
    url                = local.mongodb_url
    number_of_replicas = var.sharding.shards.replicas
    number_of_shards   = var.sharding.shards.quantity
  }
}
