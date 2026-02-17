locals {
  cluster_domain = try(coalesce(var.cluster_domain), regex("kubernetes\\s+(\\S+)\\s", data.kubernetes_config_map.dns.data["Corefile"])[0], "cluster.local")

  cors = {
    default_headers = [
      "DNT",
      "X-CustomHeader",
      "Keep-Alive,User-Agent",
      "X-Requested-With",
      "If-Modified-Since",
      "Cache-Control",
      "Content-Type",
      "Access-Control-Allow-Origin",
      "Access-Control-Allow-Methods"
    ],
    default_grpc_headers = [
      "x-grpc-web",
      "x-user-agent"
    ]
  }
  cors_all_headers = setunion(local.cors.default_headers, var.nginx.cors.allowed_headers)

  special_regex_characters = {
    "."  = "\\."
    "*"  = "\\*"
    "+"  = "\\+"
    "?"  = "\\?"
    "^"  = "\\^"
    "$"  = "\\$"
    "("  = "\\("
    ")"  = "\\)"
    "["  = "\\["
    "]"  = "\\]"
    "{"  = "\\{"
    "}"  = "\\}"
    "|"  = "\\|"
    "\\" = "\\\\"
  }

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

  target_ports = {
    http = var.tls != null ? 8443 : 8080
    grpc = var.tls != null ? 9443 : 9080
  }

  gui_url = var.gui != null ? "http://${module.gui_endpoint[0].ip}:${module.gui_endpoint[0].ports[0]}" : null

  clusters_grafana_urls = {
    for cluster_name, conf in var.clusters :
    cluster_name => conf.grafana_url if can(try(coalesce(conf.grafana_url)))
  }

  clusters_seq_urls = {
    for cluster_name, conf in var.clusters :
    cluster_name => conf.seq_url if can(try(coalesce(conf.seq_url)))
  }

  clusters_s3_urls = {
    for cluster_name, conf in var.clusters :
    cluster_name => conf.s3_urls if can(try(coalesce(conf.s3_urls)))
  }

  # If load_balancer is null, ingress module assumes its being deployed on K8s alongside an AK cluster, 
  # Thus defining nginx upstream directly to AK endpoint (first cluster from var.clusters in lexicographic order)
  upstream = var.load_balancer != null ? "${module.load_balancer_endpoint[0].host}:${module.load_balancer_endpoint[0].ports_map["grpc"]}" : trimprefix(var.clusters[keys(var.clusters)[0]].endpoint, "http://")

  #nginx_conf = var.nginx.conf_type == "ControlPlane" ? local.control_plane_nginx_conf : local.load_balancer_nginx_conf
  nginx_conf = templatefile(
    abspath("${path.module}/nginx-conf/ingress.conf.tftpl"),
    {
      nginx                 = var.nginx
      tls                   = var.tls != null
      mtls                  = var.mtls != null
      gui                   = merge(var.gui, { url = local.gui_url })
      load_balancer         = var.load_balancer != null
      upstream              = local.upstream
      cn_regex_pattern      = local.cn_regex_pattern
      cors                  = local.cors
      cors_all_headers      = local.cors_all_headers
      clusters_grafana_urls = local.clusters_grafana_urls
      clusters_seq_urls     = local.clusters_seq_urls
      clusters_s3_urls      = local.clusters_s3_urls
      default_cluster       = local.default_cluster
    }
  )
  #     ) : templatefile(
  #     abspath("${path.module}/nginx-conf-files/load-balancer.conf.tftpl"),
  #     {
  #       ingress = var.nginx
  #     }
  #   )

  static = merge(var.static, can(try(coalesce(var.environment_description))) ? { "environment.json" = var.environment_description } : {})

  #   ingress_conf = merge(var.nginx, {
  #     conf_type = "LoadBalancer"
  #     underlying_endpoint = {
  #       ip   = module.service_endpoint.ip
  #       port = module.service_endpoint.ports_map["http"]
  #     }
  #   })

  # clusters_conf = {
  #   for item in flatten([
  #     for cluster_name, conf in var.clusters : [
  #       for attr_name, value in conf.rust : !can(try(coalesce(value))) ? null : {
  #         key   = "LoadBalancer__Clusters__${title(cluster_name)}__${attr_name}"
  #         value = value
  #     }]
  #   ]) : item.key => item.value if can(try(coalesce(item.key))) && can(try(coalesce(item.value)))
  # }

  # NOTE : If var.clusters[cluster] fallback is null but cluster is the default cluster, forces fallback to be true
  fallback_clusters = var.load_balancer != null ? [
    for cluster, conf in var.clusters : cluster if coalesce(conf.fallback, false) || cluster == var.default_cluster && !can(coalesce(conf.fallback))
  ] : null

  # Adds fallback information to the clusters to be mounted in the Load Balancer's conf
  clusters_fallback_handled = var.load_balancer != null ? {
    for cluster, conf in var.clusters : cluster => merge(conf, { fallback = tobool(contains(local.fallback_clusters, cluster)) })
  } : null

  # If there is no default cluster but at least 1 cluster is the fallback, randomly chooses a fallback cluster to be the default cluster
  default_cluster = try(coalesce(var.default_cluster), local.fallback_clusters[0], null)

  clusters_conf = var.load_balancer != null ? merge([
    for cluster, conf in local.clusters_fallback_handled : {
      for attr_name, value in conf :
      "LoadBalancer__Clusters__${title(cluster)}__${join("_", [for word in split("_", attr_name) : title(word)])}" => value if can(try(coalesce(value)))
    }
  ]...) : null

  global_conf = var.load_balancer != null ? {
    for attr_name, value in try(var.load_balancer.conf, {}) :
    "LoadBalancer__${join("_", [for word in split("_", attr_name) : title(word)])}" => value if can(try(coalesce(value)))
  } : null

  generate_server_certs = !(can(coalesce(var.tls.cert_path)) && can(coalesce(var.tls.key_path)))
  generate_client_certs = var.mtls != null ? length(try(coalescelist(compact(var.mtls.generate_certs_for)), [])) > 0 : false

  formatted_custom_server_certs = var.tls != null && !local.generate_server_certs ? {
    "ingress.pem"  = format("%s\n%s", file(var.tls.cert_path), file(var.tls.key_path))
    "ingress.cert" = file(var.tls.cert_path)
    "ingress.key"  = file(var.tls.key_path)
  } : null

  formatted_generated_server_certs = var.tls != null && local.generate_server_certs ? {
    "ingress.pem" = format("%s\n%s", tls_locally_signed_cert.ingress_certificate[0].cert_pem, tls_private_key.ingress_private_key[0].private_key_pem)
    "ingress.crt" = tls_locally_signed_cert.ingress_certificate[0].cert_pem
    "ingress.key" = tls_private_key.ingress_private_key[0].private_key_pem
  } : null

  formatted_server_certs = var.tls != null ? coalesce(local.formatted_custom_server_certs, local.formatted_generated_server_certs) : null

  generated_client_ca = local.generate_client_certs ? [tls_self_signed_cert.client_root_ingress[0].cert_pem] : []

  extra_client_ca = can(coalescelist(compact(var.mtls.extra_ca_paths))) ? [
    for cert_path in var.mtls.extra_ca_paths : file(cert_path)
  ] : []

  client_ca_pem = join("\n", concat(local.generated_client_ca, local.extra_client_ca))

  common_names_map = local.generate_client_certs ? {
    for name, cert in tls_cert_request.ingress_client_cert_request :
    name => cert.subject[0].common_name
  } : {}
}
