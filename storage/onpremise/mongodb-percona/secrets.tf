# TODO: There is the option of generating a random password and then supplying it to Helm but I'd rather wait for it (connection string only available when cluster done)
resource "random_password" "app_user_password" {
  length  = 24
  special = false 
}

resource "kubernetes_secret" "application_user_password" {
  metadata {
    name      = "application-user-password" 
    namespace = var.namespace
  }

  data = {
    password = random_password.app_user_password.result
  }
}

# Build a connection string secret that ArmoniK's init jobs expect
resource "kubernetes_secret" "mongodb_connection_string" {
  metadata {
    name      = "mongodb-connection-string"
    namespace = var.namespace
  }
  data = {
    uri = "mongodb://application_user:${random_password.app_user_password.result}@${local.mongodb_dns}:${local.mongodb_port}/${var.cluster.database_name}${local.mongodb_connection_params}" #TODO: kinda annoying right meow.. end me
  }
}
