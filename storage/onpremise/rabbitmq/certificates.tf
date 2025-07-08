resource "pkcs12_from_pem" "rabbitmq_certificate" {
  password        = random_password.mq_keystore_password.result
  cert_pem        = local.client_cert
  private_key_pem = local.client_key
  ca_pem          = local.ca_cert
}

resource "kubernetes_secret" "rabbitmq_certificate" {
  metadata {
    name      = "activemq-server-certificates"
    namespace = var.namespace
  }
  data = {
    "root.pem" = local.ca_cert
    "cert.pem" = local.server_cert
    "key.pem"  = local.server_key
  }
  binary_data = {
    "certificate.pfx" = pkcs12_from_pem.rabbitmq_certificate.result
  }
}

resource "kubernetes_secret" "rabbitmq_client_certificate" {
  metadata {
    name      = "activemq-user-certificates"
    namespace = var.namespace
  }
  data = {
    "ca.pem"    = local.ca_cert
    "cert.pem"  = local.client_cert
    "chain.pem" = format("%s\n%s", local.client_cert, local.ca_cert)
  }
}

resource "local_sensitive_file" "rabbitmq_client_certificate" {
  content         = format("%s\n%s", local.client_cert, local.ca_cert)
  filename        = "${path.root}/generated/certificates/activemq/chain.pem"
  file_permission = "0600"
}
