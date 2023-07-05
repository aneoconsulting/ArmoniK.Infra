module "activemq" {
  source    = "../../activemq"
  namespace = kubernetes_namespace.armonik.metadata[0].name

  image              = "symptoma/activemq"
  tag                = "5.17.0"
  node_selector      = {}
  image_pull_secrets = ""

}
resource "kubernetes_namespace" "armonik" {
  metadata {
    name = "armonik"
  }
}
