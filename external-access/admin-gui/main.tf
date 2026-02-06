# Control plane deployment
resource "kubernetes_deployment" "admin_gui" {
  count = var.admin_gui != null ? 1 : 0
  metadata {
    name      = "admin-gui"
    namespace = var.namespace
    labels    = var.admin_gui.labels
  }
  spec {
    replicas = var.admin_gui.replicas
    selector {
      match_labels = var.admin_gui.labels
    }
    template {
      metadata {
        name      = "admin-gui"
        namespace = var.namespace
        labels    = var.admin_gui.labels
      }
      spec {
        dynamic "toleration" {
          for_each = (var.admin_gui.node_selector != {} ? [
            for key, value in var.admin_gui.node_selector : {
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
          for_each = (var.admin_gui.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.admin_gui.image_pull_secrets
          }
        }
        restart_policy = "Always" # Always, OnFailure, Never
        # App container
        container {
          name              = var.admin_gui.name
          image             = can(try(coalesce(var.admin_gui.tag))) ? "${var.admin_gui.image}:${var.admin_gui.tag}" : var.admin_gui.image
          image_pull_policy = var.admin_gui.image_pull_policy
          resources {
            limits   = var.admin_gui.limits
            requests = var.admin_gui.requests
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
    type       = var.admin_gui.service_type == "HeadLess" ? "ClusterIP" : var.admin_gui.service_type
    cluster_ip = var.admin_gui.service_type == "HeadLess" ? "None" : null
    selector = {
      app     = kubernetes_deployment.admin_gui[0].metadata[0].labels.app
      service = kubernetes_deployment.admin_gui[0].metadata[0].labels.service
    }
    port {
      name        = kubernetes_deployment.admin_gui[0].spec[0].template[0].spec[0].container[0].port[0].name
      port        = var.admin_gui.service_type == "HeadLess" ? kubernetes_deployment.admin_gui[0].spec[0].template[0].spec[0].container[0].port[0].container_port : var.admin_gui.port
      target_port = kubernetes_deployment.admin_gui[0].spec[0].template[0].spec[0].container[0].port[0].container_port
      protocol    = "TCP"
    }
  }
  timeouts {
    create = "2m"
  }
}
