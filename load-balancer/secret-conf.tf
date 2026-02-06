resource "kubernetes_secret" "load_balancer_conf" {
  metadata {
    name      = "load-balancer-conf"
    namespace = var.namespace
    labels    = var.load_balancer.labels
  }
  data = {
    "lb.yaml" = local.final_conf
  }
}
