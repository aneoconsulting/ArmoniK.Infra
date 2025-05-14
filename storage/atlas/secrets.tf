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
    name      = "mongodb"
    namespace = var.namespace
  }
  data = {
    # "ca.pem"           = tls_self_signed_cert.root_mongodb.cert_pem
    # "mongodb.pem"      = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_private_key.mongodb_private_key.private_key_pem)
    # "chain.pem"        = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_self_signed_cert.root_mongodb.cert_pem)
    username = random_string.mongodb_admin_user.result
    password = random_password.mongodb_admin_password.result
    #host               = local.mongodb_dns
    #port               = 27017
    #url                = local.mongodb_url
    #number_of_replicas = local.replicas
  }
}
