# Control plane service
resource "kubernetes_service" "metrics_exporter" {
  metadata {
    name      = var.metrics_exporter.name
    namespace = var.namespace
    labels = {
      app     = var.metrics_exporter.label_app
      service = var.metrics_exporter.label_service
    }
  }
  spec {
    type = var.service_type
    selector = {
      app     = var.metrics_exporter.label_app
      service = var.metrics_exporter.label_service
    }
    port {
      name        = var.metrics_exporter.port_name
      port        = var.metrics_exporter.port
      target_port = var.metrics_exporter.target_port
      protocol    = var.metrics_exporter.protocol
    }
  }
}
