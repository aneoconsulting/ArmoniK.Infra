locals {
  node_selector_keys   = keys(var.mongodb.node_selector)
  node_selector_values = values(var.mongodb.node_selector)
  mongodb_dns          = "${var.name}.${var.namespace}.svc"
  mongodb_url          = "mongodb://${local.mongodb_dns}/"
}
