locals {
  node_selector_keys   = keys(var.mongodb.node_selector)
  node_selector_values = values(var.mongodb.node_selector)
  mongodb_dns          = "${var.helm_release_name}-headless.${var.namespace}.svc"
  mongodb_url          = "mongodb+srv://${local.mongodb_dns}/${jsondecode(helm_release.mongodb.metadata[0].values).auth.databases[0]}"
}
