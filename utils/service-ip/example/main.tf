resource "kubernetes_service" "my_svc" {
  metadata {
    name      = "my-svc"
    namespace = var.namespace
  }
  spec {
    type       = var.type == "HeadLess" ? "ClusterIP" : var.type
    cluster_ip = var.type == "HeadLess" ? "None" : null
    selector = {
      service = "my-svc"
    }

    port {
      name        = "http"
      target_port = 80
      port        = var.type == "HeadLess" ? 80 : var.port
      protocol    = "TCP"
    }
  }
}

data "kubernetes_config_map" "dns" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }
}

locals {
  cluster_domain = try(regex("kubernetes\\s+(\\S+)\\s", data.kubernetes_config_map.dns.data["Corefile"])[0], null)
}

module "my_svc_ip" {
  source         = "./.."
  service        = kubernetes_service.my_svc
  cluster_domain = local.cluster_domain
}
