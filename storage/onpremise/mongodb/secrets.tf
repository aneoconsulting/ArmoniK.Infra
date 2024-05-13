data "kubernetes_secret" "mongodb_certificates" {
  metadata {
    name = "${helm_release.mongodb.name}-ca"
  }
  binary_data = {
    "mongodb-ca-cert" = ""
    "mongodb-ca-key"  = ""
  }
}


resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.namespace
  }
  data = {
    "chain.pem"        = base64decode(data.kubernetes_secret.mongodb_certificates.binary_data["mongodb-ca-cert"])
    username           = random_string.mongodb_application_user.result
    password           = random_password.mongodb_application_password.result
    host               = local.mongodb_dns
    port               = 27017
    url                = local.mongodb_url
    number_of_replicas = var.mongodb.replicas_number
  }
}
