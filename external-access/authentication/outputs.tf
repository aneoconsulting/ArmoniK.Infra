output "authentication_data" {
  description = "Values to be inserted into database to initiate authentication"
  value = {
    users = try(local.init_authentication_users, null)
    roles = try(local.init_authentication_roles, null)
    certs = try(local.init_authentication_certs, null)
  }
}