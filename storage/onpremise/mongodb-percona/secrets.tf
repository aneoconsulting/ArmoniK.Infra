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

  depends_on = [kubernetes_job.wait_for_percona]
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

# TLS secrets (must be created before cluster so that the operator uses them)
resource "kubernetes_secret" "ssl" {
  count = var.tls.self_managed ? 1 : 0

  metadata {
    name      = local.ssl_secret_name
    namespace = var.namespace
  }

  data = {
    "ca.crt"  = tls_self_signed_cert.ca[0].cert_pem
    "tls.crt" = format("%s\n%s", tls_locally_signed_cert.server[0].cert_pem, tls_self_signed_cert.ca[0].cert_pem)
    "tls.key" = tls_private_key.server[0].private_key_pem
  }
}

resource "kubernetes_secret" "ssl_internal" {
  count = var.tls.self_managed ? 1 : 0

  metadata {
    name      = local.ssl_internal_secret_name
    namespace = var.namespace
  }

  data = {
    "ca.crt"  = tls_self_signed_cert.ca[0].cert_pem
    "tls.crt" = format("%s\n%s", tls_locally_signed_cert.internal[0].cert_pem, tls_self_signed_cert.ca[0].cert_pem)
    "tls.key" = tls_private_key.internal[0].private_key_pem
  }
}
