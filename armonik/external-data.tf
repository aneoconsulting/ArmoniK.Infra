data "kubernetes_config_map" "dns" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }

  # This dependency ensures this data source is read *after* Kubernetes is up and running
  depends_on = [module.core_aggregation]
}

module "control_plane_endpoint" {
  source         = "../utils/service-ip"
  service        = kubernetes_service.control_plane
  cluster_domain = local.cluster_domain
}

locals {
  cluster_domain                  = try(regex("kubernetes\\s+(\\S+)\\s", data.kubernetes_config_map.dns.data["Corefile"])[0], "cluster.local")
  internal_control_plane_endpoint = "${module.control_plane_endpoint.host}:${module.control_plane_endpoint.ports[0]}"
  internal_control_plane_url      = "http://${local.internal_control_plane_endpoint}"
}
