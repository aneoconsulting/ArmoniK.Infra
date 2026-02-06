#------------------------------------------------------------------------------
# Certificate Authority
#------------------------------------------------------------------------------
resource "tls_private_key" "root_ingress" {
  count       = var.ingress.tls ? 1 : 0
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_self_signed_cert" "root_ingress" {
  count                 = length(tls_private_key.root_ingress)
  private_key_pem       = tls_private_key.root_ingress[0].private_key_pem
  is_ca_certificate     = true
  validity_period_hours = "168"
  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]
  subject {
    organization = var.certificate_authority.organization
    common_name  = var.certificate_authority.common_name
    country      = var.certificate_authority.country
  }
}

#------------------------------------------------------------------------------
# Client Certificate Authority
#------------------------------------------------------------------------------
resource "tls_private_key" "client_root_ingress" {
  count       = var.ingress.mtls && !can(try(coalesce(var.ingress.client_certs.custom_ca_file))) ? 1 : 0
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_self_signed_cert" "client_root_ingress" {
  count                 = length(tls_private_key.client_root_ingress)
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
  count       = length(tls_private_key.root_ingress)
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "tls_cert_request" "ingress_cert_request" {
  count           = length(tls_private_key.ingress_private_key)
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
  count                 = length(tls_cert_request.ingress_cert_request)
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
  count = length(tls_locally_signed_cert.ingress_certificate)
  metadata {
    name      = "${var.ingress.name}-server-certificates"
    namespace = var.namespace
  }
  data = {
    "ingress.pem" = format("%s\n%s", tls_locally_signed_cert.ingress_certificate[0].cert_pem, tls_private_key.ingress_private_key[0].private_key_pem)
    "ingress.crt" = tls_locally_signed_cert.ingress_certificate[0].cert_pem
    "ingress.key" = tls_private_key.ingress_private_key[0].private_key_pem
  }
}

#------------------------------------------------------------------------------
# Client Certificate
#------------------------------------------------------------------------------
resource "tls_private_key" "ingress_client_private_key" {
  for_each = toset(
    !var.ingress.mtls ? [] :
    length(tls_private_key.client_root_ingress) == 0 ? [] :
    var.ingress.client_certs.generate ? keys(local.permissions) : ["Submitter"]
  )
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
  count = length(tls_locally_signed_cert.ingress_client_certificate) > 0 ? 1 : 0
  metadata {
    name      = "${var.ingress.name}-user-certificates"
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
  count = length(tls_locally_signed_cert.ingress_client_certificate) > 0 || can(try(coalesce(var.ingress.client_certs.custom_ca_file))) && var.ingress.mtls ? 1 : 0
  metadata {
    name      = "${var.ingress.name}-user-certificate-authority"
    namespace = var.namespace
  }
  data = {
    "ca.pem" = can(try(coalesce(var.ingress.client_certs.custom_ca_file))) ? file(var.ingress.client_certs.custom_ca_file) : tls_self_signed_cert.client_root_ingress[0].cert_pem
  }
}

resource "local_sensitive_file" "ingress_ca" {
  count           = length(tls_self_signed_cert.root_ingress)
  content         = tls_self_signed_cert.root_ingress[0].cert_pem
  filename        = "${path.root}/generated/certificates/ingress/ca.crt"
  file_permission = "0600"
}

resource "local_sensitive_file" "ingress_client_ca" {
  count           = length(tls_self_signed_cert.client_root_ingress)
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
