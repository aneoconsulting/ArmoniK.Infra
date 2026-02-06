locals {
  armonik_cli_config = {
    endpoint              = coalesce(module.external_access[0].ingress_urls.grpc, local.control_plane_url)
    certificate_authority = module.external_access[0].certs_files.certificate_authority
    client_certificate    = module.external_access[0].certs_files.client_certificate
    client_key            = module.external_access[0].certs_files.client_key
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
    control_plane_url = can(try(coalesce(module.external_access[0].ingress_urls.grpc))) ? module.external_access[0].ingress_urls.grpc : local.control_plane_url
    grafana_url       = length(var.grafana) > 0 ? (can(try(coalesce(module.external_access[0].ingress_urls.http))) ? "${module.external_access[0].ingress_urls.http}/grafana/" : nonsensitive(var.grafana.url)) : ""
    seq_web_url       = length(var.seq) > 0 ? (can(try(coalesce(module.external_access[0].ingress_urls.http))) ? "${module.external_access[0].ingress_urls.http}/seq/" : nonsensitive(var.seq.web_url)) : ""
    admin_app_url     = var.admin_gui != null && can(try(coalesce(module.external_access[0].ingress_urls.http))) ? "${module.external_access[0].ingress_urls.http}/admin" : null
    } : {
    control_plane_url = local.control_plane_url
    grafana_url       = nonsensitive(var.grafana.url)
    seq_web_url       = nonsensitive(var.seq.web_url)
  }
}
