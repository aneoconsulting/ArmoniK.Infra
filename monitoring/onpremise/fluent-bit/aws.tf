resource "kubernetes_secret" "aws_auth_config" {
  metadata {
    name      = "aws-auth-configmap"
    namespace = var.namespace
  }
  data = {
    "credentials" = templatefile("${path.module}/configs/service/aws.conf", {
      access_key_id     = var.aws.aws_access_id,
      secret_access_key = var.aws.aws_secret_access_key,
      session_token     = var.aws.aws_session_token
    })
  }
}
