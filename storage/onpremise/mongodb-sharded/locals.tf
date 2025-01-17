locals {
  mongodb_dns           = "${var.name}.${var.namespace}.svc.cluster.local"
  mongodb_url           = "mongodb://${local.mongodb_dns}:${var.mongodb.service_port}/${var.mongodb.database_name}?authSource=admin"
  mongodb_root_password = data.kubernetes_secret.mongodb_credentials.data["mongodb-root-password"]
  mongodb_extra_flags   = ["--tlsMode=allowTLS", "--tlsCertificateKeyFile=/mongodb/mongodb.pem", "--tlsCAFile=/mongodb/chain.pem" , "--tlsAllowConnectionsWithoutCertificates"]
}
