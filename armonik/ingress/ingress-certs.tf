#------------------------------------------------------------------------------
# Certificate Authority
#------------------------------------------------------------------------------
resource "tls_private_key" "root_ingress" {
  count       = local.generate_server_certs ? 1 : 0
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_self_signed_cert" "root_ingress" {
  count                 = local.generate_server_certs ? 1 : 0
  private_key_pem       = tls_private_key.root_ingress[0].private_key_pem
  is_ca_certificate     = true
  validity_period_hours = "168"
  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]
  subject {
    organization = "ArmoniK Ingress Root (NonTrusted)"
    common_name  = "ArmoniK Ingress Root (NonTrusted) Private Certificate Authority"
    country      = "France"
  }
}

#------------------------------------------------------------------------------
# Client Certificate Authority
#------------------------------------------------------------------------------
resource "tls_private_key" "client_root_ingress" {
  count       = local.generate_client_certs ? 1 : 0
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_self_signed_cert" "client_root_ingress" {
  count                 = local.generate_client_certs ? 1 : 0
  private_key_pem       = tls_private_key.client_root_ingress[0].private_key_pem
  is_ca_certificate     = true
  validity_period_hours = "168"
  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]
  subject {
    organization = "ArmoniK Client Ingress Root (NonTrusted)"
    common_name  = "ArmoniK Client Ingress Root (NonTrusted) Private Certificate Authority"
    country      = "France"
  }
}

#------------------------------------------------------------------------------
# Server Certificate
#------------------------------------------------------------------------------
resource "tls_private_key" "ingress_private_key" {
  count       = local.generate_server_certs ? 1 : 0
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_cert_request" "ingress_cert_request" {
  count           = local.generate_server_certs ? 1 : 0
  private_key_pem = tls_private_key.ingress_private_key[0].private_key_pem
  subject {
    country     = "France"
    common_name = "armonik.local"
  }
  ip_addresses = compact([
    try(kubernetes_service.ingress.spec[0].cluster_ip, null),
    try(kubernetes_service.ingress.status[0].load_balancer[0].ingress[0].ip, null)
  ])
}

resource "tls_locally_signed_cert" "ingress_certificate" {
  count                 = local.generate_server_certs ? 1 : 0
  cert_request_pem      = tls_cert_request.ingress_cert_request[0].cert_request_pem
  ca_private_key_pem    = tls_private_key.root_ingress[0].private_key_pem
  ca_cert_pem           = tls_self_signed_cert.root_ingress[0].cert_pem
  validity_period_hours = "168"
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "any_extended",
  ]
}

resource "kubernetes_secret" "ingress_certificate" {
  count = var.tls != null ? 1 : 0
  metadata {
    name      = "${var.nginx.name}-server-certs"
    namespace = var.namespace
  }
  data = local.formatted_server_certs
}

#------------------------------------------------------------------------------
# Client Certificate
#------------------------------------------------------------------------------
resource "tls_private_key" "ingress_client_private_key" {
  for_each    = local.generate_client_certs ? var.mtls.generate_certs_for : toset([])
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "random_string" "common_name" {
  for_each = tls_private_key.ingress_client_private_key
  length   = 16
  special  = false
  numeric  = false
}

resource "tls_cert_request" "ingress_client_cert_request" {
  for_each        = tls_private_key.ingress_client_private_key
  private_key_pem = each.value.private_key_pem
  subject {
    country     = "France"
    common_name = random_string.common_name[each.key].result
    # organization = "127.0.0.1"
  }
}

resource "tls_locally_signed_cert" "ingress_client_certificate" {
  for_each              = tls_cert_request.ingress_client_cert_request
  cert_request_pem      = each.value.cert_request_pem
  ca_private_key_pem    = tls_private_key.client_root_ingress[0].private_key_pem
  ca_cert_pem           = tls_self_signed_cert.client_root_ingress[0].cert_pem
  validity_period_hours = "168"
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "any_extended",
  ]
}

resource "pkcs12_from_pem" "ingress_client_pkcs12" {
  for_each        = tls_locally_signed_cert.ingress_client_certificate
  password        = ""
  cert_pem        = each.value.cert_pem
  private_key_pem = tls_private_key.ingress_client_private_key[each.key].private_key_pem
  ca_pem          = tls_self_signed_cert.client_root_ingress[0].cert_pem
}

resource "kubernetes_secret" "ingress_client_certificate" {
  count = local.generate_client_certs ? 1 : 0
  metadata {
    name      = "${var.nginx.name}-client-certs"
    namespace = var.namespace
  }
  data = merge([for name, cert in tls_locally_signed_cert.ingress_client_certificate :
    {
      "client.${lower(name)}.crt" = cert.cert_pem,
      "client.${lower(name)}.key" = tls_private_key.ingress_client_private_key[name].private_key_pem,
      "client.${lower(name)}.p12" = pkcs12_from_pem.ingress_client_pkcs12[name].result,
    }
  ]...)
}

resource "kubernetes_secret" "ingress_client_certificate_authority" {
  count = var.mtls != null ? 1 : 0
  metadata {
    name      = "${var.nginx.name}-client-ca"
    namespace = var.namespace
  }
  data = {
    "ca.pem" = local.client_ca_pem
  }
}

resource "local_sensitive_file" "ingress_ca" {
  count           = local.generate_server_certs ? 1 : 0
  content         = tls_self_signed_cert.root_ingress[0].cert_pem
  filename        = "${path.root}/generated/certificates/ingress/ca.crt"
  file_permission = "0600"
}

resource "local_sensitive_file" "ingress_client_ca" {
  count           = local.generate_client_certs ? 1 : 0
  content         = tls_self_signed_cert.client_root_ingress[0].cert_pem
  filename        = "${path.root}/generated/certificates/ingress/client_ca.crt"
  file_permission = "0600"
}

resource "local_sensitive_file" "ingress_client_crt" {
  for_each        = tls_locally_signed_cert.ingress_client_certificate
  content         = each.value.cert_pem
  filename        = "${path.root}/generated/certificates/ingress/client.${lower(each.key)}.crt"
  file_permission = "0600"
}

resource "local_sensitive_file" "ingress_client_key" {
  for_each        = tls_private_key.ingress_client_private_key
  content         = each.value.private_key_pem
  filename        = "${path.root}/generated/certificates/ingress/client.${lower(each.key)}.key"
  file_permission = "0600"
}

resource "local_sensitive_file" "ingress_client_p12" {
  for_each        = pkcs12_from_pem.ingress_client_pkcs12
  content_base64  = each.value.result
  filename        = "${path.root}/generated/certificates/ingress/client.${lower(each.key)}.p12"
  file_permission = "0600"
}
