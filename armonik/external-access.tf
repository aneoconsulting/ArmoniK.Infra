locals {
  ingress_new_conf = !can(try(coalesce(var.ingress))) ? null : {
    underlying_endpoint = local.control_plane_endpoints
    client_certs = {
      generate       = var.ingress.generate_client_cert
      custom_ca_file = var.ingress.custom_client_ca_file
    }
    cors = {
      allowed_host      = var.ingress.cors_allowed_host
      allowed_headers   = var.ingress.cors_allowed_headers
      allowed_methods   = var.ingress.cors_allowed_methods
      preflight_max_age = var.ingress.cors_preflight_max_age
    }
  }
  ingress_conf = merge(var.ingress, local.ingress_new_conf)
}

module "external_access" {
  count                   = can(try(coalesce(var.ingress))) ? 1 : 0
  source                  = "../external-access/"
  namespace               = var.namespace
  cluster_domain          = local.cluster_domain
  ingress                 = local.ingress_conf
  static                  = var.static
  environment_description = var.environment_description
  authentication = {
    trusted_common_names = try(var.authentication.trusted_common_names, null)
    datafile             = try(var.authentication.authentication_datafile, null)
    permissions          = local.ingress_generated_cert.permissions
  }
  services_urls = {
    grafana = try(var.grafana.url, null)
    seq     = try(var.seq.web_url, null)
  }
  shared_storage = {
    type = try(local.file_storage_type, null)
    urls = {
      service = try(var.shared_storage_settings.service_url, null)
      console = try(var.shared_storage_settings.console_url, null)
    }
  }
  admin_gui = var.admin_gui
}
