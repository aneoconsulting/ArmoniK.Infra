# resource "tls_private_key" "load_balancer_private_key" {
#   count       = length(tls_private_key.root_load_balancer)
#   algorithm   = "RSA"
#   ecdsa_curve = "P384"
#   rsa_bits    = "4096"
# }

# resource "tls_cert_request" "load_balancer_cert_request" {
#   count           = length(tls_private_key.load_balancer_private_key)
#   private_key_pem = tls_private_key.load_balancer_private_key[0].private_key_pem
#   subject {
#     country     = "France"
#     common_name = "armonik.mcp.local"
#   }
#   ip_addresses = compact([
#     try(kubernetes_service.load_balancer.spec[0].cluster_ip, null),
#   ])
# }

# resource "tls_locally_signed_cert" "load_balancer_certificate" {
#   count                 = length(tls_cert_request.load_balancer_cert_request)
#   cert_request_pem      = tls_cert_request.load_balancer_cert_request[0].cert_request_pem
#   ca_private_key_pem    = tls_private_key.root_ingress[0].private_key_pem
#   ca_cert_pem           = tls_self_signed_cert.root_ingress[0].cert_pem
#   validity_period_hours = "168"
#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#     "client_auth",
#     "any_extended",
#   ]
# }

# resource "kubernetes_secret" "load_balancer_certificate" {
#   count = local.formatted_server_certs != null ? 1 : 0
#   metadata {
#     name      = "${var.nginx.name}-server-certificates"
#     namespace = var.namespace
#   }
#   data = local.formatted_server_certs
# }
