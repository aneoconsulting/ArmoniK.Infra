locals {
  ssc              = var.shared_storage_settings
  s3_conf_required = can(coalesce(local.ssc.service_url)) && can(coalesce(local.ssc.console_url)) && lower(local.ssc.file_storage_type) == "s3"
}

module "ingress" {
  count          = var.ingress != null ? 1 : 0
  source         = "./ingress/"
  namespace      = var.namespace
  cluster_domain = local.cluster_domain
  tls            = try(coalesce(var.ingress.tls), false) ? {} : null

  mtls = try(coalesce(var.ingress.mtls), false) ? {
    generate_certs_for = var.ingress.generate_client_cert ? local.generate_certs_for : null
    extra_ca_paths     = compact(split(",", var.ingress.custom_client_ca_file))
    trusted_cns        = var.authentication.trusted_common_names
  } : null

  gui = merge(var.admin_gui, {
    langs = try(coalesce(var.ingress.langs), null)
  })

  nginx = merge(var.ingress, {
    service = {
      type = var.ingress.service_type
    }
    cors = {
      allowed_host      = var.ingress.cors_allowed_host
      allowed_headers   = var.ingress.cors_allowed_headers
      allowed_methods   = var.ingress.cors_allowed_methods
      preflight_max_age = var.ingress.cors_preflight_max_age
    }
  })

  clusters = {
    local = merge({
      endpoint    = local.internal_control_plane_url
      grafana_url = try(coalesce(var.grafana.url), null)
      seq_url     = try(coalesce(var.seq.web_url), null)
      extra_headers = var.load_balancer != null && var.authentication.require_authentication ? {
        "X-Certificate-Client-CN"          = local.username_common_name_map["loadbalancer"]
        "X-Certificate-Client-Fingerprint" = local.username_fingerprint_map["loadbalancer"]
      } : null
      s3_urls = local.s3_conf_required ? {
        service = local.ssc.service_url
        console = local.ssc.console_url
      } : null
    })
  }
  default_cluster         = "local"
  load_balancer           = var.load_balancer
  environment_description = var.environment_description
  static                  = var.static
}
