data "kubernetes_config_map" "dns" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }
}

locals {
  cluster_domain = try(regex("kubernetes\\s+(\\S+)\\s", data.kubernetes_config_map.dns.data["Corefile"])[0], "cluster.local")
}

module "service_endpoint" {
  source         = "../../../utils/service-ip"
  service        = kubernetes_service.test
  cluster_domain = local.cluster_domain
}

module "mock_ingress" {
  source = "../"
  ingress = {
    name      = "lb"
    conf_type = "LoadBalancer"
    underlying_endpoint = {
      ip   = module.service_endpoint.host
      port = module.service_endpoint.ports[0]
    }
    tls  = true
    mtls = true
    client_certs = {
      custom_ca_file = ""
    }
  }
  namespace      = "default"
  cluster_domain = local.cluster_domain
}
