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

output "endpoint_urls" {
  description = "List of URL endpoints for: control-plane, Seq, Grafana and Admin GUI"
  value = {
    control_plane = local.base_endpoints.grpc
    grafana       = can(coalesce(var.clusters[var.default_cluster].grafana_url)) ? "${local.base_endpoints.http}/grafana" : null
    seq_web       = can(coalesce(var.clusters[var.default_cluster].seq_url)) ? "${local.base_endpoints.http}/seq" : null
    admin_app     = var.gui != null ? "${local.base_endpoints.http}/admin" : ""
  }
}

output "endpoint_cluster_urls" {
  description = "List of URL endpoints for: control-plane, Seq, Grafana and Admin GUI"
  value = {
    for cluster in keys(var.clusters) :
    cluster => {
      grafana = "${local.base_endpoints.http}/${cluster}/grafana"
      seq     = "${local.base_endpoints.http}/${cluster}/seq"
    }
  }
}