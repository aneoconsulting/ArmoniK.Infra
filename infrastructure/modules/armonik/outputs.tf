# Armonik control plane
output "control_plane_url" {
  description = "Endpoint URL of ArmoniK control plane"
  value       = local.control_plane_url
}
# Armonik admin API
output "admin_api_url" {
  description = "Endpoint URL of ArmoniK admin API"
  value       = local.admin_api_url
}
# Armonik admin App
output "admin_app_url" {
  description = "Endpoint URL of ArmoniK admin App"
  value       = local.admin_app_url
}

output "ingress" {
  description = "ingress endpoint"
  value       = {
    http              = local.ingress_http_url
    grpc              = local.ingress_grpc_url
    control_plane_url = local.ingress_grpc_url != "" ? local.ingress_grpc_url : local.control_plane_url
    grafana_url       = local.grafana_url != "" ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/grafana/" : local.grafana_url) : ""
    seq_web_url       = local.seq_url != "" ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/seq/" : local.seq_web_url) : ""
    admin_api_url     = local.ingress_http_url != "" ? "${local.ingress_http_url}/api" : local.admin_api_url
    admin_app_url     = local.ingress_http_url != "" ? "${local.ingress_http_url}/" : local.admin_app_url
  }
}
