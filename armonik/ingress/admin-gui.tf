# Control plane deployment
resource "kubernetes_deployment" "admin_gui" {
  count = var.gui != null ? 1 : 0
  metadata {
    name      = "admin-gui"
    namespace = var.namespace
    labels    = var.gui.labels
  }
  spec {
    replicas = var.gui.replicas
    selector {
      match_labels = var.gui.labels
    }
    template {
      metadata {
        name      = "admin-gui"
        namespace = var.namespace
        labels    = var.gui.labels
      }
      spec {
        dynamic "toleration" {
          for_each = (var.gui.node_selector != {} ? [
            for key, value in var.gui.node_selector : {
              key   = key
              value = value
            }
          ] : [])
          content {
            key      = toleration.value.key
            operator = "Equal"
            value    = toleration.value.value
            effect   = "NoSchedule"
          }
        }
        dynamic "image_pull_secrets" {
          for_each = (var.gui.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.gui.image_pull_secrets
          }
        }
        restart_policy = "Always" # Always, OnFailure, Never
        # App container
        container {
          name              = var.gui.name
          image             = can(try(coalesce(var.gui.tag))) ? "${var.gui.image}:${var.gui.tag}" : var.gui.image
          image_pull_policy = var.gui.image_pull_policy
          resources {
            limits   = var.gui.limits
            requests = var.gui.requests
          }
          port {
            name           = "app-port"
            container_port = 1080
          }
        }
      }
    }
  }
}

# Admin GUI service
resource "kubernetes_service" "admin_gui" {
  count = length(kubernetes_deployment.admin_gui)
  metadata {
    name      = kubernetes_deployment.admin_gui[0].metadata[0].name
    namespace = kubernetes_deployment.admin_gui[0].metadata[0].namespace
    labels = {
      app     = kubernetes_deployment.admin_gui[0].metadata[0].labels.app
      service = kubernetes_deployment.admin_gui[0].metadata[0].labels.service
    }
  }
  spec {
    type       = var.gui.service_type == "HeadLess" ? "ClusterIP" : var.gui.service_type
    cluster_ip = var.gui.service_type == "HeadLess" ? "None" : null
    selector = {
      app     = kubernetes_deployment.admin_gui[0].metadata[0].labels.app
      service = kubernetes_deployment.admin_gui[0].metadata[0].labels.service
    }
    port {
      name        = kubernetes_deployment.admin_gui[0].spec[0].template[0].spec[0].container[0].port[0].name
      port        = var.gui.service_type == "HeadLess" ? kubernetes_deployment.admin_gui[0].spec[0].template[0].spec[0].container[0].port[0].container_port : var.gui.port
      target_port = kubernetes_deployment.admin_gui[0].spec[0].template[0].spec[0].container[0].port[0].container_port
      protocol    = "TCP"
    }
  }
  timeouts {
    create = "2m"
  }
}
