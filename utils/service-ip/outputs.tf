output "ip" {
  description = "IP of the service"
  value = var.service != null ? try(
    # load balancer
    coalesce(var.service.status[0].load_balancer[0].ingress[0].ip),
    coalesce(var.service.status[0].load_balancer[0].ingress[0].hostname),

    # cluster ip
    coalesce(var.service.spec[0].cluster_ip != "None" ? var.service.spec[0].cluster_ip : null),

    # Headless
    "${var.service.metadata[0].name}.${var.service.metadata[0].namespace}.svc.${var.domain}"
  ) : null
}

output "ports" {
  description = "Ports of the service"
  value       = var.service == null ? null : var.service.spec[0].cluster_ip != "None" ? var.service.spec[0].port[*].port : var.service.spec[0].port[*].target_port
}
