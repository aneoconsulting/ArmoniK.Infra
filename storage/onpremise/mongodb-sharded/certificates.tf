#------------------------------------------------------------------------------
# Certificate Authority
#------------------------------------------------------------------------------
resource "tls_private_key" "root_mongodb" {
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_self_signed_cert" "root_mongodb" {
  private_key_pem       = tls_private_key.root_mongodb.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = var.validity_period_hours
  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]
  subject {
    organization = "ArmoniK mongodb Root (NonTrusted)"
    common_name  = "ArmoniK mongodb Root (NonTrusted) Private Certificate Authority"
    country      = "France"
  }
}

#------------------------------------------------------------------------------
# Certificate
#------------------------------------------------------------------------------
resource "tls_private_key" "mongodb_private_key" {
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_cert_request" "mongodb_cert_request" {
  private_key_pem = tls_private_key.mongodb_private_key.private_key_pem
  subject {
    country     = "France"
    common_name = local.mongodb_dns
    # organization = "127.0.0.1"
  }

  dns_names = [
    local.mongodb_dns,
    var.name,
    "${var.name}.${var.namespace}",
    "${var.name}.${var.namespace}.svc",
    "${var.name}.${var.namespace}.svc.cluster.local",
    "localhost"
  ]
}

resource "tls_locally_signed_cert" "mongodb_certificate" {
  cert_request_pem      = tls_cert_request.mongodb_cert_request.cert_request_pem
  ca_private_key_pem    = tls_private_key.root_mongodb.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.root_mongodb.cert_pem
  validity_period_hours = var.validity_period_hours
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "any_extended",
  ]
}

#------------------------------------------------------------------------------
# Kubernetes Secrets with certificates
#------------------------------------------------------------------------------

resource "kubernetes_secret" "mongodb_certificate" {
  metadata {
    name      = "${var.name}-server-certificates"
    namespace = var.namespace
  }
  data = {
    "mongodb.pem" = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_private_key.mongodb_private_key.private_key_pem)
    "chain.pem"   = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_self_signed_cert.root_mongodb.cert_pem)
    "ca.pem"      = tls_self_signed_cert.root_mongodb.cert_pem
  }
}

resource "local_sensitive_file" "mongodb_client_certificate" {
  content         = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_self_signed_cert.root_mongodb.cert_pem)
  filename        = "${path.root}/generated/certificates/${var.name}/chain.pem"
  file_permission = "0600"
}
