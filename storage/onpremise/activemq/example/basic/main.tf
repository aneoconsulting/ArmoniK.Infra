module "activemq" {
  source             = "../../../activemq"
  namespace          = kubernetes_namespace.armonik.metadata[0].name
  name               = var.name
  image              = var.image
  tag                = var.tag
  node_selector      = var.node_selector
  image_pull_secrets = var.image_pull_secrets
}

resource "kubernetes_namespace" "armonik" {
  metadata {
    name = var.namespace
  }
}
