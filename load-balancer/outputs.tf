output "urls" {
  description = "External access to the Load Balancer's ingress"
  value = {
    "grpc" = module.external_access.ingress_urls.grpc
    "http" = module.external_access.ingress_urls.http
  }
}
