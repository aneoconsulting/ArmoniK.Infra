output "ip" {
  description = "IP of the service"
  value = var.service != null ? try(
    # load balancer
    coalesce(var.service.status[0].load_balancer[0].ingress[0].ip),
    coalesce(var.service.status[0].load_balancer[0].ingress[0].hostname),

    # cluster ip
    coalesce(var.service.spec[0].cluster_ip != "None" ? var.service.spec[0].cluster_ip : null),

    # Headless
    local.fqdn
  ) : null
}

output "domain" {
  description = "Domain Name of the service"
  value       = local.domain
}

output "fqdn" {
  description = "Fully Qualified Domain Name (FQDN) of the service"
  value       = local.fqdn
}

output "ports" {
  description = "Ports of the service"
  value       = var.service == null ? null : var.service.spec[0].cluster_ip != "None" ? var.service.spec[0].port[*].port : var.service.spec[0].port[*].target_port
}
