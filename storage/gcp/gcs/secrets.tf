#secret for credential to variable
resource "kubernetes_secret" "s3_user_credentials" {
  metadata {
    name      = "${var.name}-s3-user-credentials"
    namespace = var.namespace
  }
  data = {
    "S3__Login"    = var.username
    "S3__Password" = var.password
  }
}
