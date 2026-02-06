data "kubernetes_config_map" "dns" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }
}

module "admin_gui" {
  count          = var.admin_gui != null ? 1 : 0
  source         = "./admin-gui"
  admin_gui      = var.admin_gui
  namespace      = var.namespace
  cluster_domain = local.cluster_domain
}

module "ingress" {
  source                  = "./ingress"
  ingress                 = var.ingress
  namespace               = var.namespace
  static                  = var.static
  services_urls           = local.ingress_services_urls
  environment_description = var.environment_description
  shared_storage          = var.shared_storage
  certificate_authority   = var.certificate_authority
  authentication          = var.authentication
  cluster_domain          = local.cluster_domain
}
