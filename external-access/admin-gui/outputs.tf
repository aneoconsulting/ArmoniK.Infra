module "admin_gui_endpoint" {
  source         = "../../utils/service-ip"
  service        = one(kubernetes_service.admin_gui)
  cluster_domain = var.cluster_domain
}

output "url" {
  description = "Endpoint of the admin GUI"
  value       = "http://${module.admin_gui_endpoint.host}:${module.admin_gui_endpoint.ports[0]}"
}
