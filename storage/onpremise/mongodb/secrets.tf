data "kubernetes_secret" "mongodb_certificates" {
  metadata {
    name      = "${helm_release.mongodb.name}-ca"
    namespace = var.namespace
  }
}

# resource "kubernetes_secret" "mongodb" {
#   metadata {
#     name      = "mongodb"
#     namespace = var.namespace
#   }
#   data = {
#     "ca.pem"           = tls_self_signed_cert.root_mongodb.cert_pem
#     "mongodb.pem"      = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_private_key.mongodb_private_key.private_key_pem)
#     "chain.pem"        = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_self_signed_cert.root_mongodb.cert_pem)
#     username           = random_string.mongodb_application_user.result
#     password           = random_password.mongodb_application_password.result
#     host               = local.mongodb_dns
#     port               = 27017
#     url                = local.mongodb_url
#     number_of_replicas = local.replicas
#   }
# }
