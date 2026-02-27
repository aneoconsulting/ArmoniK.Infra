locals {
  prefix         = can(coalesce(var.name)) ? "${var.name}-" : ""
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
}
