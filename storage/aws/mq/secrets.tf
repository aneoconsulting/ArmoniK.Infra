#secret for credential to variable

resource "kubernetes_secret" "activemq_user_credentials" {
  metadata {
    name      = "activemq-user-credentials"
    namespace = var.namespace
  }
  data = {
    "Amqp__User"     = var.username
    "Amqp__Password" = var.password
  }
}
