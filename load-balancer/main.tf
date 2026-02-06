# Control plane deployment
resource "kubernetes_deployment" "load_balancer" {
  metadata {
    name        = "armonik-load-balancer"
    namespace   = var.namespace
    labels      = var.load_balancer.labels
    annotations = var.load_balancer.annotations
  }
  spec {
    replicas = var.load_balancer.replicas
    selector {
      match_labels = var.load_balancer.labels
    }
    template {
      metadata {
        name        = "armonik-load-balancer"
        namespace   = var.namespace
        labels      = var.load_balancer.labels
        annotations = var.load_balancer.annotations
      }
      spec {
        node_selector  = var.load_balancer.node_selector
        restart_policy = "Always" # Always, OnFailure, Never
        dynamic "toleration" {
          for_each = (var.load_balancer.node_selector != {} ? [
            for key, value in var.load_balancer.node_selector : {
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
          for_each = can(try(coalesce(var.load_balancer.image_pull_secrets))) ? [1] : []
          content {
            name = var.load_balancer.image_pull_secrets
          }
        }
        volume {
          name = "config"
          secret {
            secret_name = kubernetes_secret.load_balancer_conf.metadata[0].name
          }
        }
        container {
          name              = "load-balancer"
          image             = can(try(coalesce(var.load_balancer.tag))) ? "${var.load_balancer.image}:${var.load_balancer.tag}" : var.load_balancer.image
          image_pull_policy = var.load_balancer.image_pull_policy
          args              = ["-c", "/lb.yaml"]
          resources {
            limits   = var.load_balancer.limits
            requests = var.load_balancer.requests
          }
          port {
            name           = "http"
            container_port = var.load_balancer.port
          }
          volume_mount {
            name       = "config"
            mount_path = "/etc/"
          }
          dynamic "env" {
            for_each = can(try(coalesce(var.load_balancer.config))) ? [1] : []
            content {
              name  = "RUST_LOG"
              value = var.load_balancer.config.rust_log
            }
          }
        }
      }
    }
  }
}
# Control plane service
resource "kubernetes_service" "load_balancer" {
  metadata {
    name        = "armonik-load-balancer"
    namespace   = var.namespace
    labels      = var.load_balancer.labels
    annotations = var.load_balancer.annotations
  }
  spec {
    type       = var.load_balancer.service_type == "HeadLess" ? "ClusterIP" : var.load_balancer.service_type
    cluster_ip = var.load_balancer.service_type == "HeadLess" ? "None" : null
    selector   = var.load_balancer.labels
    port {
      name        = "http"
      port        = var.load_balancer.service_type == "HeadLess" ? var.load_balancer.port : 8080
      target_port = var.load_balancer.port
      protocol    = "TCP"
    }
  }
}
