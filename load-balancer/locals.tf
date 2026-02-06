locals {
  ingress_conf = merge(var.ingress, {
    conf_type = "LoadBalancer"
    underlying_endpoint = {
      ip   = module.service_endpoint.ip
      port = module.service_endpoint.ports_map["http"]
    }
  })

  clusters_conf = {
    clusters = {
      for cluster_name, cluster in var.clusters_config :
      cluster_name => cluster
    }
  }
  load_balancer_conf = can(try(coalesce(var.load_balancer.conf))) ? {
    for key, value in var.load_balancer.conf : key => value
  } : null
  final_conf = yamlencode(merge(local.clusters_conf, local.load_balancer_conf))
}
