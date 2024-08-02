output "endpoint_urls" {
  description = "List of URL endpoints for: control-plane, Seq, Grafana and Admin GUI"
  value = var.ingress != null ? {
    control_plane_url = local.ingress_grpc_url != "" ? local.ingress_grpc_url : local.control_plane_url
    grafana_url       = length(var.grafana_output) > 0 ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/grafana/" : nonsensitive(var.grafana_output[0].url)) : ""
    seq_web_url       = length(var.seq_output) > 0 ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/seq/" : nonsensitive(var.seq_output[0].web_url)) : ""
    admin_app_url     = length(kubernetes_service.admin_gui) > 0 ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/admin" : local.admin_app_url) : null
    admin_api_url     = length(kubernetes_service.admin_0_8_gui) > 0 ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/api" : local.admin_api_url) : null
    admin_0_8_url     = length(kubernetes_service.admin_0_8_gui) > 0 ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/admin-0.8" : local.admin_0_8_url) : null
    admin_0_9_url     = length(kubernetes_service.admin_0_9_gui) > 0 ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/admin-0.9" : local.admin_0_9_url) : null
    } : {
    control_plane_url = local.control_plane_url
    grafana_url       = nonsensitive(var.grafana_output[0].url)
    seq_web_url       = nonsensitive(var.seq_output[0].web_url)
    admin_app_url     = local.admin_app_url
    admin_api_url     = local.admin_api_url
    admin_0_8_url     = local.admin_0_8_url
    admin_0_9_url     = local.admin_0_9_url
  }
}
