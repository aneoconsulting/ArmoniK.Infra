data "kubernetes_service" "rabbitmq" {
  metadata {

    name      = "rabbitmq"
    namespace = var.namespace
  }
  depends_on = [helm_release.rabbitmq]
}

data "kubernetes_secret" "rabbitmq_certs" {
  metadata {
    name      = "rabbitmq-certs"
    namespace = var.namespace
  }
  depends_on = [helm_release.rabbitmq]
}

locals {
  rabbitmq_endpoints = {
    ip       = data.kubernetes_service.rabbitmq.spec[0].cluster_ip
    port     = data.kubernetes_service.rabbitmq.spec[0].port[1].port
    web_port = data.kubernetes_service.rabbitmq.spec[0].port[3].port
  }
  ca_cert     = data.kubernetes_secret.rabbitmq_certs.data["ca.crt"]
  client_cert = data.kubernetes_secret.rabbitmq_certs.data["tls.crt"]
  client_key  = data.kubernetes_secret.rabbitmq_certs.data["tls.key"]
  server_cert = data.kubernetes_secret.rabbitmq_certs.data["tls.crt"]
  server_key  = data.kubernetes_secret.rabbitmq_certs.data["tls.key"]

  rabbitmq_url     = "amqps://${local.rabbitmq_endpoints.ip}:${local.rabbitmq_endpoints.port}"
  rabbitmq_web_url = "http://${local.rabbitmq_endpoints.ip}:${local.rabbitmq_endpoints.web_port}"
}
