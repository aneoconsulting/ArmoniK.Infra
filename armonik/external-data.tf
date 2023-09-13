data "kubernetes_config_map" "dns" {
  metadata {
    name = "coredns"
    # This dummy regex replace is used to ensure this data source is read *after* Kubernetes is up and running
    namespace = replace(data.kubernetes_secret.deployed_object_storage.id, "/.*/", "kube-system")
  }
}

module "control_plane_endpoint" {
  source         = "../utils/service-ip"
  service        = kubernetes_service.control_plane
  cluster_domain = local.cluster_domain
}

module "admin_gui_endpoint" {
  source         = "../utils/service-ip"
  service        = one(kubernetes_service.admin_gui)
  cluster_domain = local.cluster_domain
}

# Deprecated, must be removed in a future version
module "admin_0_8_gui_endpoint" {
  source         = "../utils/service-ip"
  service        = one(kubernetes_service.admin_0_8_gui)
  cluster_domain = local.cluster_domain
}

# Deprecated, must be removed in a future version
module "admin_0_9_gui_endpoint" {
  source         = "../utils/service-ip"
  service        = one(kubernetes_service.admin_0_9_gui)
  cluster_domain = local.cluster_domain
}

module "ingress_endpoint" {
  source         = "../utils/service-ip"
  service        = one(kubernetes_service.ingress)
  cluster_domain = local.cluster_domain
}

locals {
  cluster_domain = try(regex("kubernetes\\s+(\\S+)\\s", data.kubernetes_config_map.dns.data["Corefile"])[0], "cluster.local")
  control_plane_endpoints = {
    ip   = module.control_plane_endpoint.host
    port = module.control_plane_endpoint.ports[0]
  }
  admin_gui_endpoints = {
    ip       = module.admin_gui_endpoint.host
    app_port = try(module.admin_gui_endpoint.ports[0], null)
  }
  # Deprecated, must be removed in a future version
  admin_0_8_gui_endpoints = {
    ip       = module.admin_0_8_gui_endpoint.host
    api_port = try(module.admin_0_8_gui_endpoint.ports[0], null)
    app_port = try(module.admin_0_8_gui_endpoint.ports[1], null)
  }
  # Deprecated, must be removed in a future version
  admin_0_9_gui_endpoints = {
    ip   = module.admin_0_9_gui_endpoint.host
    port = try(module.admin_0_9_gui_endpoint.ports[0], null)
  }
  ingress_endpoint = {
    ip        = module.ingress_endpoint.host
    http_port = var.ingress.http_port
    grpc_port = var.ingress.grpc_port
  }
  control_plane_url = "http://${local.control_plane_endpoints.ip}:${local.control_plane_endpoints.port}"
  admin_app_url     = length(kubernetes_service.admin_gui) > 0 ? "http://${local.admin_gui_endpoints.ip}:${local.admin_gui_endpoints.app_port}" : null
  # Deprecated, must be removed in a future version
  admin_api_url = length(kubernetes_service.admin_0_8_gui) > 0 ? "http://${local.admin_0_8_gui_endpoints.ip}:${local.admin_0_8_gui_endpoints.api_port}/api" : null
  # Deprecated, must be removed in a future version
  admin_0_8_url = length(kubernetes_service.admin_0_8_gui) > 0 ? "http://${local.admin_0_8_gui_endpoints.ip}:${local.admin_0_8_gui_endpoints.app_port}/" : null
  # Deprecated, must be removed in a future version
  admin_0_9_url    = length(kubernetes_service.admin_0_9_gui) > 0 ? "http://${local.admin_0_9_gui_endpoints.ip}:${local.admin_0_9_gui_endpoints.port}/" : null
  ingress_http_url = var.ingress != null ? "${var.ingress.tls ? "https" : "http"}://${local.ingress_endpoint.ip}:${local.ingress_endpoint.http_port}" : ""
  ingress_grpc_url = var.ingress != null ? "${var.ingress.tls ? "https" : "http"}://${local.ingress_endpoint.ip}:${local.ingress_endpoint.grpc_port}" : ""
}
