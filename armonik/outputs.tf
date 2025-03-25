locals {

  armonik_cli_config = {
    endpoint              = coalesce(local.ingress_grpc_url, local.control_plane_url)
    certificate_authority = try(abspath(local_sensitive_file.ingress_ca[0].filename), null)
    client_certificate    = try(abspath(local_sensitive_file.ingress_client_crt["Submitter"].filename), null)
    client_key            = try(abspath(local_sensitive_file.ingress_client_key["Submitter"].filename), null)
  }

}

# Create the configuration file
resource "local_file" "armonik_config" {
  content         = "# ArmoniK Connection Configuration\n---\n${yamlencode({ for k, v in local.armonik_cli_config : k => v if v != null })}"
  filename        = "${path.root}/generated/armonik-cli.yaml"
  file_permission = "0644"
}

output "armonik_config_file" {
  description = "Path to the generated ArmoniK configuration file"
  value       = abspath(local_file.armonik_config.filename)
}


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
