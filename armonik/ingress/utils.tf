data "kubernetes_config_map" "dns" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }
}

# Needed for leveraging fingerprint output, not available in resource's output
data "tls_certificate" "client_certificates" {
  for_each = tls_locally_signed_cert.ingress_client_certificate
  content  = each.value.cert_pem
}

module "load_balancer_endpoint" {
  count          = can(try(coalesce(var.load_balancer))) ? 1 : 0
  source         = "../../utils/service-ip"
  service        = kubernetes_service.load_balancer[0]
  cluster_domain = local.cluster_domain
}

module "gui_endpoint" {
  count          = can(try(coalesce(var.gui))) ? 1 : 0
  source         = "../../utils/service-ip"
  service        = kubernetes_service.admin_gui[0]
  cluster_domain = local.cluster_domain
}

module "ingress_endpoint" {
  source         = "../../utils/service-ip"
  service        = kubernetes_service.ingress
  cluster_domain = local.cluster_domain
}
