#secret for credential to variable
resource "kubernetes_secret" "redis_user_credentials" {
  metadata {
    name      = "redis-user-credentials"
    namespace = var.namespace
  }
  data = {
    "Redis__User"     = ""
    "Redis__Password" = google_redis_instance.cache.auth_string
  }
}

resource "kubernetes_secret" "redis_ca" {
  metadata {
    name      = "redis-ca"
    namespace = var.namespace
  }
  data = {
    "chain.pem" = join("\n", google_redis_instance.cache.server_ca_certs[*].cert)
  }
}
