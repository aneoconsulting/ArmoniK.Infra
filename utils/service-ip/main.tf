# Service IP

locals {
  cluster_domain = coalesce(var.cluster_domain, "cluster.local")
  domain         = var.service != null ? "${var.service.metadata[0].name}.${var.service.metadata[0].namespace}" : null
  fqdn           = var.service != null ? "${local.domain}.svc.${local.cluster_domain}" : null
  ip = var.service != null ? try(
    # load balancer
    coalesce(var.service.status[0].load_balancer[0].ingress[0].ip),
    coalesce(var.service.status[0].load_balancer[0].ingress[0].hostname),

    # cluster ip
    coalesce(var.service.spec[0].cluster_ip != "None" ? var.service.spec[0].cluster_ip : null),

    # Headless
    null
  ) : null
}
