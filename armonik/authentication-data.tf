# loadbalancer built-in user common name is either hard-coded or provided
resource "random_string" "common_name" {
  for_each = ["submitter", "monitoring"]
  length   = 16
  special  = false
  numeric  = false
}

locals {
  # Retrieve user-provided authentication data
  custom_auth_file  = can(coalesce(var.authentication.authentication_datafile)) ? jsondecode(file(var.authentication.authentication_datafile)) : null
  custom_users_list = try(local.custom_auth_file.users_list, [])
  custom_roles_list = try(local.custom_auth_file.roles_list, [])
  custom_certs_list = try(local.custom_auth_file.certificates_list, [])

  # Map of users and their set of roles
  provided_users = {
    for obj in local.custom_users_list :
    obj.Username => obj.Roles
  }

  # Map of roles and their set of permissions
  provided_roles = {
    for obj in local.custom_roles_list :
    obj.RoleName => obj.Permissions
  }

  # Map of user and their authentication information
  provided_auth_data = {
    for obj in local.custom_certs_list :
    obj.Username => {
      fingerprint = obj.Fingerprint
      common_name = obj.Cn
    }
  }

  # Map of roles and their set of permissions
  builtin_roles = merge(
    var.ingress.generate_client_cert ? {
      Submitter  = local.submitter_permissions
      Monitoring = local.monitoring_permissions
    } : null,
    var.load_balancer != null ? {             # Ensures that 'Submitter' role is created when
      Submitter = local.submitter_permissions # Load Balancer is enabled but no client certificate generation is required
    } : null
  )

  # Map of users and their set of roles
  builtin_users = merge(
    var.ingress.generate_client_cert ? {
      submitter  = ["Submitter"]
      monitoring = ["Monitoring"]
    } : null,
    var.load_balancer != null ? {
      loadbalancer = ["Submitter"]
    } : null
  )

  # If relevant, creates the map of built-in users and their generated common name that will be passed down to ingress module
  generate_certs_for = {
    for user, str in random_string.common_name :
    user => {
      common_name = str.result
    } if !contains(keys(local.provided_auth_data), user) # Only generate cert if auth data for matching user are not provided
  }

  # Retrieves generated certificates' fingerprint
  client_certs = try(module.ingress[0].client_certificates, {})

  builtin_users_auth_data = merge(
    {
      for u, cert in local.client_certs :
      u => {
        fingerprint = cert.certificates[length(cert.certificates) - 1].sha1_fingerprint
        common_name = random_string.common_name[u]
      }
    },
    var.load_balancer != null ? {
      loadbalancer = {
        fingerprint = "iamarmonikloadbalancer"
        common_name = "armonik.loadbalancer"
      }
    } : null
  )

  users     = merge(local.builtin_users, local.provided_users)
  roles     = merge(local.builtin_roles, local.provided_roles)
  auth_data = merge(local.builtin_users_auth_data, local.provided_auth_data)
}
