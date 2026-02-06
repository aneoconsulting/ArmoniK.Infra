output "ingress_urls" {
  description = "Maps of URL by protocol"
  value       = module.ingress.urls
}

output "init_authentication" {
  description = "Values to be inserted into database to initiate authentication"
  value       = module.ingress.init_authentication
}

output "certs_files" {
  description = "Path to certificates"
  value       = module.ingress.certs_files
}
