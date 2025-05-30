resource "kubernetes_secret" "activemq" {
  metadata {
    name      = "activemq"
    namespace = var.namespace
  }
  data = {
    "ca.pem"              = tls_self_signed_cert.root_activemq.cert_pem
    "cert.pem"            = format("%s\n%s", tls_locally_signed_cert.activemq_certificate.cert_pem, tls_private_key.activemq_private_key.private_key_pem)
    "chain.pem"           = format("%s\n%s", tls_locally_signed_cert.activemq_certificate.cert_pem, tls_self_signed_cert.root_activemq.cert_pem)
    username              = random_string.mq_application_user.result
    password              = random_password.mq_application_password.result
    host                  = local.activemq_endpoints.ip
    port                  = local.activemq_endpoints.port
    url                   = local.activemq_url
    web_url               = local.activemq_web_url
    adapter_class_name    = local.adapter_class_name
    adapter_absolute_path = local.adapter_absolute_path
    engine_type           = local.engine_type
  }
}
