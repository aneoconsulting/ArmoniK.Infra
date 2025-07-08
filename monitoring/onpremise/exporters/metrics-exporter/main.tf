# Control plane service
resource "kubernetes_service" "metrics_exporter" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      app     = var.label_app
      service = var.label_service
    }
  }
  spec {
    type = var.service_type
    selector = {
      app     = var.label_app
      service = var.label_service
    }
    port {
      name        = var.port_name
      port        = var.port
      target_port = var.target_port
      protocol    = "TCP"
    }
  }
}
