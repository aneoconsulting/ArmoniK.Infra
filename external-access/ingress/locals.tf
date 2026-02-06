locals {
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
  cors_all_headers = setunion(local.cors.default_headers, var.ingress.cors.allowed_headers)

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
  escaped_common_names = [
    for str in var.authentication.trusted_common_names : join("", [
      for char in split("", str) : (
        lookup(local.special_regex_characters, char, char)
      )
    ])
  ]

  # Regex pattern to match only trusted common names
  cn_regex_pattern = join("|", local.escaped_common_names)

  target_ports = {
    http = var.ingress.tls ? 8443 : 8080
    grpc = var.ingress.tls ? 9443 : 9080
  }

  #nginx_conf = var.ingress.conf_type == "ControlPlane" ? local.control_plane_nginx_conf : local.load_balancer_nginx_conf
  nginx_conf = var.ingress.conf_type == "ControlPlane" ? templatefile(
    abspath("${path.module}/nginx-conf-files/control-plane.conf.tftpl"),
    {
      ingress          = var.ingress
      services_urls    = var.services_urls
      shared_storage   = var.shared_storage
      cn_regex_pattern = local.cn_regex_pattern
      cors             = local.cors
      cors_all_headers = local.cors_all_headers

    }
    ) : templatefile(
    abspath("${path.module}/nginx-conf-files/load-balancer.conf.tftpl"),
    {
      ingress = var.ingress
    }
  )

  static = merge(var.static, can(try(coalesce(var.environment_description))) ? { "environment.json" = var.environment_description } : {})
}
