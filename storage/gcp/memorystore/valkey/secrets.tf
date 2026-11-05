# CA of the instance, which Core needs to check the server certificate. Empty without TLS, Core then ignores it
resource "kubernetes_secret" "redis_ca" {
  metadata {
    name      = "redis-ca"
    namespace = var.namespace
  }
  data = {
    "chain.pem" = local.ca_certificates
  }
}
