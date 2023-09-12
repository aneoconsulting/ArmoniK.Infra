output "ip" {
  description = "IP of the service"
  value       = local.ip
}

output "domain" {
  description = "Domain Name of the service"
  value       = local.domain
}

output "fqdn" {
  description = "Fully Qualified Domain Name (FQDN) of the service"
  value       = local.fqdn
}

output "host" {
  description = "Either the IP or the FQDN of the service"
  value       = coalesce(local.ip, local.fqdn, "toto")
}

output "ports" {
  description = "Ports of the service"
  value       = var.service == null ? null : var.service.spec[0].cluster_ip != "None" ? var.service.spec[0].port[*].port : var.service.spec[0].port[*].target_port
}
