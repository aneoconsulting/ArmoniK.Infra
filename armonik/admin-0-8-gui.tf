# Control plane deployment
resource "kubernetes_deployment" "admin_0_8_gui" {
  count = var.admin_0_8_gui != null ? 1 : 0
  metadata {
    name      = "admin-0-8-gui"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      service = "app-gui"
    }
  }
  spec {
    replicas = var.admin_0_8_gui.replicas
    selector {
      match_labels = {
        app     = "armonik"
        service = "admin-0-8-gui"
      }
    }
    template {
      metadata {
        name      = "admin-0-8-gui"
        namespace = var.namespace
        labels = {
          app     = "armonik"
          service = "admin-0-8-gui"
        }
      }
      spec {
        dynamic "toleration" {
          for_each = (local.admin_0_8_gui_node_selector != {} ? [
            for index in range(0, length(local.admin_0_8_gui_node_selector_keys)) : {
              key   = local.admin_0_8_gui_node_selector_keys[index]
              value = local.admin_0_8_gui_node_selector_values[index]
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
          for_each = (var.admin_0_8_gui.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.admin_0_8_gui.image_pull_secrets
          }
        }
        restart_policy = "Always" # Always, OnFailure, Never
        # API container, only needed for 0_8 GUI
        container {
          name              = var.admin_0_8_gui.api.name
          image             = var.admin_0_8_gui.api.tag != "" ? "${var.admin_0_8_gui.api.image}:${var.admin_0_8_gui.api.tag}" : var.admin_0_8_gui.api.image
          image_pull_policy = var.admin_0_8_gui.image_pull_policy
          resources {
            limits   = var.admin_0_8_gui.api.limits
            requests = var.admin_0_8_gui.api.requests
          }
          port {
            name           = "api-port"
            container_port = 3333
          }
        }
        # 0_8 GUI container
        container {
          name              = var.admin_0_8_gui.app.name
          image             = var.admin_0_8_gui.app.tag != "" ? "${var.admin_0_8_gui.app.image}:${var.admin_0_8_gui.app.tag}" : var.admin_0_8_gui.app.image
          image_pull_policy = var.admin_0_8_gui.image_pull_policy
          resources {
            limits   = var.admin_0_8_gui.app.limits
            requests = var.admin_0_8_gui.app.requests
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

# Admin 0_8 GUI service
resource "kubernetes_service" "admin_0_8_gui" {
  count = length(kubernetes_deployment.admin_0_8_gui)
  metadata {
    name      = kubernetes_deployment.admin_0_8_gui[0].metadata[0].name
    namespace = kubernetes_deployment.admin_0_8_gui[0].metadata[0].namespace
    labels = {
      app     = kubernetes_deployment.admin_0_8_gui[0].metadata[0].labels.app
      service = kubernetes_deployment.admin_0_8_gui[0].metadata[0].labels.service
    }
  }
  spec {
    type       = var.admin_0_8_gui.service_type == "HeadLess" ? "ClusterIP" : var.admin_0_8_gui.service_type
    cluster_ip = var.admin_0_8_gui.service_type == "HeadLess" ? "None" : null
    selector = {
      app     = kubernetes_deployment.admin_0_8_gui[0].metadata[0].labels.app
      service = kubernetes_deployment.admin_0_8_gui[0].metadata[0].labels.service
    }
    port {
      name        = kubernetes_deployment.admin_0_8_gui[0].spec[0].template[0].spec[0].container[0].port[0].name
      port        = var.admin_0_8_gui.service_type == "HeadLess" ? kubernetes_deployment.admin_0_8_gui[0].spec[0].template[0].spec[0].container[0].port[0].container_port : var.admin_0_8_gui.api.port
      target_port = kubernetes_deployment.admin_0_8_gui[0].spec[0].template[0].spec[0].container[0].port[0].container_port
      protocol    = "TCP"
    }
    port {
      name        = kubernetes_deployment.admin_0_8_gui[0].spec[0].template[0].spec[0].container[1].port[0].name
      port        = var.admin_0_8_gui.service_type == "HeadLess" ? kubernetes_deployment.admin_0_8_gui[0].spec[0].template[0].spec[0].container[0].port[0].container_port : var.admin_0_8_gui.app.port
      target_port = kubernetes_deployment.admin_0_8_gui[0].spec[0].template[0].spec[0].container[1].port[0].container_port
      protocol    = "TCP"
    }
  }
  timeouts {
    create = "2m"
  }
}
