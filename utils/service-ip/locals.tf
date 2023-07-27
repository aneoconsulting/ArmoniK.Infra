locals {
  domain = "${var.service.metadata[0].name}.${var.service.metadata[0].namespace}"
  fqdn   = "${local.service_domain}.svc.${var.cluster_domain}"
}
