module "service_endpoint" {
  source         = "../../utils/service-ip"
  service        = kubernetes_service.ingress
  cluster_domain = var.cluster_domain
}

output "urls" {
  description = "Maps of URL by protocol"
  value = {
    http = "${var.ingress.tls ? "https" : "http"}://${module.service_endpoint.host}:${module.service_endpoint.ports_map["http"]}"
    grpc = "${var.ingress.tls ? "https" : "http"}://${module.service_endpoint.host}:${module.service_endpoint.ports_map["grpc"]}"
  }
}

output "init_authentication" {
  description = "Values to be inserted into database to initiate authentication"
  value = module.authentication[0].authentication_data
}

output "certs_files" {
  description = "Path to certificates"
  value = {
    certificate_authority = try(abspath(local_sensitive_file.ingress_ca[0].filename), null)
    client_certificate    = try(abspath(local_sensitive_file.ingress_client_crt["Submitter"].filename), null)
    client_key            = try(abspath(local_sensitive_file.ingress_client_key["Submitter"].filename), null)
  }
}
