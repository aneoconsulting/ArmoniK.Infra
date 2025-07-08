locals {
  # Endpoint urls
  load_balancer = (kubernetes_service.metrics_exporter.spec[0].type == "LoadBalancer" ? {
    ip   = (kubernetes_service.metrics_exporter.status[0].load_balancer[0].ingress[0].ip == "" ? kubernetes_service.metrics_exporter.status[0].load_balancer[0].ingress[0].hostname : kubernetes_service.metrics_exporter.status[0].load_balancer[0].ingress[0].ip)
    port = kubernetes_service.metrics_exporter.spec[0].port[0].port
    } : {
    ip   = ""
    port = ""
  })

  metrics_exporter_endpoints = (local.load_balancer.ip == "" && kubernetes_service.metrics_exporter.spec[0].type == "ClusterIP" ? {
    ip   = kubernetes_service.metrics_exporter.spec[0].cluster_ip
    port = kubernetes_service.metrics_exporter.spec[0].port[0].port
    } : {
    ip   = local.load_balancer.ip
    port = local.load_balancer.port
  })

  url = "http://${local.metrics_exporter_endpoints.ip}:${local.metrics_exporter_endpoints.port}"
}
