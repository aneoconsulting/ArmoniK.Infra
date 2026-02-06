data "tls_certificate" "certificate_data" {
  for_each = var.client_certificates
  content  = each.value.cert_pem
}

locals {
  init_authentication_provided = can(coalesce(var.authentication.datafile)) ? jsondecode(file(var.authentication.datafile)) : null
  init_authentication_users = local.init_authentication_provided == null ? [
    for name, cert in data.tls_certificate.certificate_data : {
      Username = name,
      Roles    = [name]
    }
  ] : local.init_authentication_provided.users_list
  init_authentication_roles = local.init_authentication_provided == null ? [
    for name, cert in data.tls_certificate.certificate_data : {
      RoleName    = name,
      Permissions = var.authentication.permissions[name]
    }
  ] : local.init_authentication_provided.roles_list

  init_authentication_certs = local.init_authentication_provided == null ? [
    for name, cert in data.tls_certificate.certificate_data : {
      Fingerprint = cert.certificates[length(cert.certificates) - 1].sha1_fingerprint,
      Cn          = var.client_certs_requests[name].subject[0].common_name,
      Username    = name
    }
  ] : local.init_authentication_provided.certificates_list
}
