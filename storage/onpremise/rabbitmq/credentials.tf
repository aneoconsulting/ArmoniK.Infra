resource "random_string" "mq_application_user" {
  length  = 8
  special = false
  numeric = false
}

resource "random_password" "mq_application_password" {
  length  = 16
  special = false
}

resource "random_password" "mq_keystore_password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "rabbitmq_user" {
  metadata {
    name      = "rabbitmq-user"
    namespace = var.namespace
  }
  data = {
    username = random_string.mq_application_user.result
    password = random_password.mq_application_password.result
  }
  type = "kubernetes.io/basic-auth"
}

#secret for credential to variable

resource "kubernetes_secret" "rabbitmq_user_credentials" {
  metadata {
    name      = "rabbitmq-user-credentials"
    namespace = var.namespace
  }
  data = {
    "Amqp__User"     = random_string.mq_application_user.result
    "Amqp__Password" = random_password.mq_application_password.result
  }
}
