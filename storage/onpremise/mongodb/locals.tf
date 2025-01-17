locals {
  mongodb_dns = "${var.name}-headless.${var.namespace}.svc.cluster.local"
  mongodb_url = "mongodb+srv://${local.mongodb_dns}/${jsondecode(helm_release.mongodb.metadata[0].values).auth.databases[0]}"
    mongodb_root_password = data.kubernetes_secret.mongodb_credentials.data["mongodb-root-password"]
  mongodb_extra_flags   = ["--tlsMode=allowTLS", "--tlsCertificateKeyFile=/mongodb/mongodb.pem", "--tlsCAFile=/mongodb/chain.pem", "--tlsAllowConnectionsWithoutCertificates"]

}
