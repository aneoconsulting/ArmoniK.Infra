#secret for credential to variable

resource "kubernetes_secret" "activemq_user_credentials" {
  metadata {
    name      = "activemq-user-credentials"
    namespace = var.namespace
  }
  data = {
    "Amqp__User"     = local.username
    "Amqp__Password" = local.password
  }
}
