locals {
  mongodb_dns = "${var.name}-headless.${var.namespace}.svc"
  mongodb_url = "mongodb+srv://${local.mongodb_dns}/${jsondecode(helm_release.mongodb.metadata[0].values).auth.databases[0]}"
}
