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

resource "kubernetes_secret" "mongodb_connection_string" {
  metadata {
    name      = "mongodb-connection-string"
    namespace = var.namespace
  }
  data = {
    uri = "mongodb://application_user:${random_password.app_user_password.result}@${local.mongodb_dns}:${local.mongodb_port}/${var.cluster.database_name}${local.mongodb_connection_params}"
  }
}

data "kubernetes_secret" "percona_cluster_secrets" {
  metadata {
    name      = local.secrets_name
    namespace = var.namespace
  }

  depends_on = [kubectl_manifest.cluster]
}


resource "kubernetes_secret" "mongodb_monitoring_connection_string" {
  metadata {
    name      = "mongodb-monitoring-connection-string"
    namespace = var.namespace
  }

  data = {
    uri = join("", [
      "mongodb://",
      data.kubernetes_secret.percona_cluster_secrets.data["MONGODB_CLUSTER_MONITOR_USER"],
      ":",
      data.kubernetes_secret.percona_cluster_secrets.data["MONGODB_CLUSTER_MONITOR_PASSWORD"],
      "@",
      local.mongodb_dns,
      ":",
      local.mongodb_port,
      "/admin",
    local.mongodb_connection_params])
  }
}
