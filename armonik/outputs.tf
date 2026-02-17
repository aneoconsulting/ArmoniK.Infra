locals {
  armonik_cli_config = {
    endpoint              = coalesce(try(module.ingress[0].ingress_urls.grpc, ""), local.internal_control_plane_url)
    certificate_authority = try(module.ingress[0].certs_files.certificate_authority, "")
    client_certificate    = try(module.ingress[0].certs_files.client_certificate, "")
    client_key            = try(module.ingress[0].certs_files.client_key, "")
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
  value = {
    control_plane_url = try(module.ingress[0].endpoint_urls.control_plane, local.internal_control_plane_url)
    grafana_url       = try(module.ingress[0].endpoint_urls.grafana, nonsensitive(var.grafana.url))
    seq_web_url       = try(module.ingress[0].endpoint_urls.seq_web, nonsensitive(var.seq.web_url))
    admin_app_url     = try(coalesce(module.ingress[0].endpoint_urls.admin_app), null)
  }
}
