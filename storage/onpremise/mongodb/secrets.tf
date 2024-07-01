# data "kubernetes_secret" "mongodb_certificates" {
#   metadata {
#     name      = "${helm_release.mongodb.name}-ca"
#     namespace = var.namespace
#   }
# }

resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.namespace
  }
  data = {
    "chain.pem"        = "" # data.kubernetes_secret.mongodb_certificates.data["mongodb-ca-cert"]
    username           = "root"
    password           = data.kubernetes_secret.mongodb_credentials.data["mongodb-root-password"]
    host               = local.mongodb_dns
    port               = 27017
    url                = local.mongodb_url
    number_of_replicas = var.mongodb.replicas_number
  }
}
