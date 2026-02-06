module "service_endpoint" {
  source  = "../utils/service-ip"
  service = kubernetes_service.load_balancer
}

module "external_access" {
  source                  = "../external-access/"
  namespace               = var.namespace
  ingress                 = local.ingress_conf
  static                  = var.static
  environment_description = var.environment_description
  authentication = {
    trusted_common_names = try(var.authentication.trusted_common_names, null)
    datafile             = try(var.authentication.authentication_datafile, null)
  }
  admin_gui = var.admin_gui
}
