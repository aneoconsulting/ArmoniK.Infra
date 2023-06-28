module "activemq" {
  source    = "../../activemq"
  namespace = kubernetes_namespace.armonik.metadata[0].name
  activemq = {
    image              = "symptoma/activemq"
    tag                = "5.17.0"
    node_selector      = {}
    image_pull_secrets = ""
  }
}
resource "kubernetes_namespace" "armonik" {
  metadata {
    name = "armonik"
  }
}

provider "kubernetes" {
  #config_path    = var.k8s_config_path
  #config_context = lookup(tomap(data.external.k8s_config_context.result), "k8s_config_context", var.k8s_config_context)
  config_path    = "/home/adem/.kube/config"
  config_context = "default"
}
