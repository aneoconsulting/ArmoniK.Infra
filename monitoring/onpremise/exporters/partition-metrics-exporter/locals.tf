locals {
  node_selector_keys   = keys(var.node_selector)
  node_selector_values = values(var.node_selector)

  # Metrics exporter
  metrics_exporter_host = split(":", try(var.metrics_exporter_url, ""))[0]
  metrics_exporter_port = split(":", try(var.metrics_exporter_url, ""))[1]

  # Endpoint urls
  load_balancer = (kubernetes_service.partition_metrics_exporter.spec[0].type == "LoadBalancer" ? {
    ip   = (kubernetes_service.partition_metrics_exporter.status[0].load_balancer[0].ingress[0].ip == "" ? kubernetes_service.partition_metrics_exporter.status[0].load_balancer[0].ingress[0].hostname : kubernetes_service.partition_metrics_exporter.status[0].load_balancer[0].ingress[0].ip)
    port = kubernetes_service.partition_metrics_exporter.spec[0].port[0].port
    } : {
    ip   = ""
    port = ""
  })

  partition_metrics_exporter_endpoints = (local.load_balancer.ip == "" && kubernetes_service.partition_metrics_exporter.spec[0].type == "ClusterIP" ? {
    ip   = kubernetes_service.partition_metrics_exporter.spec[0].cluster_ip
    port = kubernetes_service.partition_metrics_exporter.spec[0].port[0].port
    } : {
    ip   = local.load_balancer.ip
    port = local.load_balancer.port
  })

  url = "http://${local.partition_metrics_exporter_endpoints.ip}:${local.partition_metrics_exporter_endpoints.port}"
}
