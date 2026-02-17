locals {

  tls_conf = try(coalesce(var.ingress.tls), false) ? {} : null
  #   cert_path = ""
  #   key_path = ""
  # } : null

  mtls_conf = try(coalesce(var.ingress.mtls), false) ? {
    generate_certs_for = var.ingress.generate_client_cert ? keys(local.ingress_generated_cert.permissions) : null
    extra_ca_paths     = compact(split(",", var.ingress.custom_client_ca_file))
    trusted_cns        = var.authentication.trusted_common_names
  } : null

  gui_conf = merge(var.admin_gui, {
    langs = try(coalesce(var.ingress.langs), null)
  })

  nginx_conf = var.ingress == null ? null : {
    name               = var.ingress.name
    replicas           = var.ingress.replicas
    image              = var.ingress.image
    tag                = var.ingress.tag
    image_pull_policy  = var.ingress.image_pull_policy
    http_port          = var.ingress.http_port
    grpc_port          = var.ingress.grpc_port
    limits             = var.ingress.limits
    requests           = var.ingress.requests
    image_pull_secrets = var.ingress.image_pull_secrets
    node_selector      = var.ingress.node_selector
    annotations        = var.ingress.annotations
    service = {
      type = var.ingress.service_type
    }
    cors = {
      allowed_host      = var.ingress.cors_allowed_host
      allowed_headers   = var.ingress.cors_allowed_headers
      allowed_methods   = var.ingress.cors_allowed_methods
      preflight_max_age = var.ingress.cors_preflight_max_age
    }
  }

  ssc              = var.shared_storage_settings
  s3_conf_required = can(try(coalesce(local.ssc.service_url))) && can(try(coalesce(local.ssc.console_url))) && lower(local.ssc.file_storage_type) == "s3"

  clusters_conf = {
    local = {
      endpoint    = local.internal_control_plane_url
      grafana_url = try(coalesce(var.grafana.url), null)
      seq_url     = try(coalesce(var.seq.web_url), null)
      s3_urls = local.s3_conf_required ? {
        service = local.ssc.service_url
        console = local.ssc.console_url
      } : null
    }
  }
}

module "ingress" {
  count                   = var.ingress != null ? 1 : 0
  source                  = "./ingress/"
  namespace               = var.namespace
  cluster_domain          = local.cluster_domain
  tls                     = local.tls_conf
  mtls                    = local.mtls_conf
  gui                     = local.gui_conf
  nginx                   = local.nginx_conf
  clusters                = local.clusters_conf
  load_balancer           = var.load_balancer
  environment_description = var.environment_description
  static                  = var.static
}
