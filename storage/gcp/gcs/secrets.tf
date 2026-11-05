# HMAC credentials of the S3 adapter of Core, only when given
resource "kubernetes_secret" "s3_user_credentials" {
  count = var.username != null && var.password != null ? 1 : 0
  metadata {
    name      = "${var.name}-s3-user-credentials"
    namespace = var.namespace
  }
  data = {
    "S3__Login"    = var.username
    "S3__Password" = var.password
  }
}

moved {
  from = kubernetes_secret.s3_user_credentials
  to   = kubernetes_secret.s3_user_credentials[0]
}
