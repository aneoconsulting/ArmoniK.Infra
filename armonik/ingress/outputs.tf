locals {
  base_endpoints = {
    http = "${var.tls != null ? "https" : "http"}://${module.ingress_endpoint.host}:${module.ingress_endpoint.ports_map["http"]}"
    grpc = "${var.tls != null ? "https" : "http"}://${module.ingress_endpoint.host}:${module.ingress_endpoint.ports_map["grpc"]}"
  }
}

output "certs_files" {
  description = "Path to certificates"
  value = {
    certificate_authority = try(abspath(local_sensitive_file.ingress_ca[0].filename), null)
    client_certificate    = try(abspath(local_sensitive_file.ingress_client_crt[*].filename), null)
    client_key            = try(abspath(local_sensitive_file.ingress_client_key[*].filename), null)
  }
}

output "client_certificates" {
  description = "List of client certificates with their corresponding private keys and CA certificate"
  value       = try(data.tls_certificate.client_certificates, null)
}

output "common_names_map" {
  description = "List of client certificate common names"
  value       = local.common_names_map
}

output "endpoint_urls" {
  description = "List of URL endpoints for: control-plane, Seq, Grafana and Admin GUI"
  value = {
    control_plane = local.base_endpoints.grpc
    grafana       = length(local.clusters_grafana_urls) > 0 ? { for cluster_name, url in local.clusters_grafana_urls : cluster_name => "${local.base_endpoints.http}/${cluster_name}/grafana" } : null
    seq_web       = length(local.clusters_seq_urls) > 0 ? { for cluster_name, url in local.clusters_seq_urls : cluster_name => "${local.base_endpoints.http}/${cluster_name}/seq" } : null
    admin_app     = var.gui != null ? "${local.base_endpoints.http}/admin" : ""
  }
}
