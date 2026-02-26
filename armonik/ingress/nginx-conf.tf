locals {
  # Escape common names to be matched as a literal
  escaped_common_names = !can(coalescelist(var.mtls.trusted_cns)) ? [] : [
    for str in var.mtls.trusted_cns : join("", [
      for char in split("", str) : (
        lookup(local.special_regex_characters, char, char)
      )
    ])
  ]

  # Regex pattern to match only trusted common names
  cn_regex_pattern = join("|", local.escaped_common_names)

  gui_url = var.gui != null ? "http://${module.gui_endpoint[0].ip}:${module.gui_endpoint[0].ports[0]}" : null

  clusters_grafana_urls = {
    for cluster, conf in var.clusters :
    cluster => conf.grafana_url if can(coalesce(conf.grafana_url))
  }

  clusters_seq_urls = {
    for cluster, conf in var.clusters :
    cluster => conf.seq_url if can(coalesce(conf.seq_url))
  }

  clusters_s3_urls = {
    for cluster, conf in var.clusters :
    cluster => conf.s3_urls if can(coalesce(conf.s3_urls))
  }

  # If load_balancer is null, ingress module assumes its being deployed on K8s alongside an AK cluster, 
  # Thus defining nginx upstream directly to AK endpoint (default cluster if so, or first cluster from var.clusters in lexicographic order)
  upstream = var.load_balancer != null ? "${module.load_balancer_endpoint[0].host}:${module.load_balancer_endpoint[0].ports_map["grpc"]}" : trimprefix(try(var.clusters[var.default_cluster].endpoint, var.clusters[keys(var.clusters)[0]].endpoint), "http://")

  nginx_conf = templatefile(
    abspath("${path.module}/nginx-conf/ingress.conf.tftpl"),
    {
      nginx                 = var.nginx
      tls                   = var.tls != null
      mtls                  = var.mtls != null
      gui                   = merge({ langs = [] }, var.gui, { url = local.gui_url })
      load_balancer         = var.load_balancer != null
      upstream              = local.upstream
      cn_regex_pattern      = local.cn_regex_pattern
      cors                  = local.cors
      cors_all_headers      = local.cors_all_headers
      clusters_grafana_urls = local.clusters_grafana_urls
      clusters_seq_urls     = local.clusters_seq_urls
      clusters_s3_urls      = local.clusters_s3_urls
      default_cluster       = var.default_cluster
    }
  )
  static = merge(var.static, can(coalesce(var.environment_description)) ? { "environment.json" = var.environment_description } : {})
}

resource "kubernetes_config_map" "nginx" {
  count = var.nginx != null ? 1 : 0
  metadata {
    name      = "${local.prefix}nginx-conf"
    namespace = var.namespace
  }
  data = {
    "armonik.conf" = local.nginx_conf
  }
}

resource "kubernetes_config_map" "static" {
  count = var.nginx != null ? 1 : 0
  metadata {
    name      = "${local.prefix}nginx-static"
    namespace = var.namespace
  }
  data = {
    for k, v in local.static :
    k => jsonencode(v)
  }
}

resource "local_file" "nginx_conf_file" {
  count           = var.nginx != null ? 1 : 0
  content         = local.nginx_conf
  filename        = "${path.root}/generated/configmaps/ingress/armonik.conf"
  file_permission = "0644"
}
