locals {
  cluster_domain = try(coalesce(var.cluster_domain), regex("kubernetes\\s+(\\S+)\\s", data.kubernetes_config_map.dns.data["Corefile"])[0], "cluster.local")
  ingress_services_urls = merge(var.services_urls, {
    admin_gui = try(module.admin_gui[0].url, "")
  })
}
