resource "random_string" "mq_admin_user" {
  length  = 8
  special = false
  numeric = false
}

resource "random_password" "mq_admin_password" {
  length  = 16
  special = false
}

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

resource "kubernetes_secret" "activemq_admin" {
  metadata {
    name      = "activemq-admin"
    namespace = var.namespace
  }
  data = {
    username = random_string.mq_admin_user.result
    password = random_password.mq_admin_password.result
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "activemq_user" {
  metadata {
    name      = "activemq-user"
    namespace = var.namespace
  }
  data = {
    username = random_string.mq_application_user.result
    password = random_password.mq_application_password.result
  }
  type = "kubernetes.io/basic-auth"
}

#secret for credential to variable

resource "kubernetes_secret" "activemq_user_credentials" {
  metadata {
    name      = "activemq-user-credentials"
    namespace = var.namespace
  }
  data = {
    "Amqp__User"     = random_string.mq_application_user.result
    "Amqp__Password" = random_password.mq_application_password.result
  }
}
