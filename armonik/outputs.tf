output "endpoint_urls" {
  description = "List of URL endpoints for: control-plane, Seq, Grafana and Admin GUI"
  value = var.ingress != null ? {
    control_plane_url = local.ingress_grpc_url != "" ? local.ingress_grpc_url : local.control_plane_url
    grafana_url       = length(var.grafana) > 0 ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/grafana/" : nonsensitive(var.grafana.url)) : ""
    seq_web_url       = length(var.seq) > 0 ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/seq/" : nonsensitive(var.seq.web_url)) : ""
    admin_app_url     = length(kubernetes_service.admin_gui) > 0 ? (local.ingress_http_url != "" ? "${local.ingress_http_url}/admin" : local.admin_app_url) : null
    } : {
    control_plane_url = local.control_plane_url
    grafana_url       = nonsensitive(var.grafana.url)
    seq_web_url       = nonsensitive(var.seq.web_url)
    admin_app_url     = local.admin_app_url
  }
}
