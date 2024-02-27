resource "kubernetes_secret" "rabbitmq" {
  metadata {
    name      = "activemq"
    namespace = var.namespace
  }
  data = {
    "chain.pem"           = format("%s\n%s", local.client_cert, local.ca_cert)
    username              = random_string.mq_application_user.result
    password              = random_password.mq_application_password.result
    host                  = local.rabbitmq_endpoints.ip
    port                  = local.rabbitmq_endpoints.port
    url                   = local.rabbitmq_url
    web_url               = local.rabbitmq_web_url
    adapter_class_name    = local.adapter_class_name
    adapter_absolute_path = local.adapter_absolute_path
    engine_type           = local.engine_type
  }
  depends_on = [data.kubernetes_service.rabbitmq]
}
