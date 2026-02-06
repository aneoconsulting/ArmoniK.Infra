# Nginx Ingress deployment
resource "kubernetes_deployment" "ingress" {
  metadata {
    name      = var.ingress.name
    namespace = var.namespace
    labels = var.ingress.labels
  }
  spec {
    replicas = var.ingress.replicas
    selector {
      match_labels = var.ingress.labels
    }
    template {
      metadata {
        name        = var.ingress.name
        namespace   = var.namespace
        labels      = var.ingress.labels
        annotations = var.ingress.annotations
      }
      spec {
        node_selector = var.ingress.node_selector
        dynamic "toleration" {
          for_each = (var.ingress.node_selector != {} ? [
            for key, value in var.ingress.node_selector : {
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
          for_each = (var.ingress.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.ingress.image_pull_secrets
          }
        }
        restart_policy = "Always" # Always, OnFailure, Never
        # Control plane container
        container {
          name              = var.ingress.name
          image             = can(try(coalesce(var.ingress.tag))) ? "${var.ingress.image}:${var.ingress.tag}" : var.ingress.image
          image_pull_policy = var.ingress.image_pull_policy
          resources {
            limits   = var.ingress.limits
            requests = var.ingress.requests
          }
          dynamic "port" {
            for_each = local.target_ports
            content {
              name           = port.key
              container_port = port.value
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.ingress[0].metadata[0].name
            }
          }
          dynamic "volume_mount" {
            for_each = kubernetes_secret.ingress_certificate
            content {
              name       = "ingress-secret-volume"
              mount_path = "/ingress"
              read_only  = true
            }
          }
          dynamic "volume_mount" {
            for_each = kubernetes_secret.ingress_client_certificate_authority
            content {
              name       = "ingress-client-secret-volume"
              mount_path = "/ingressclient"
              read_only  = true
            }
          }
          volume_mount {
            name       = "ingress-nginx"
            mount_path = "/etc/nginx/conf.d"
            read_only  = true
          }
          volume_mount {
            name       = "static"
            mount_path = "/static"
            read_only  = true
          }
        }
        dynamic "volume" {
          for_each = kubernetes_secret.ingress_certificate
          content {
            name = "ingress-secret-volume"
            secret {
              secret_name = volume.value.metadata[0].name
              optional    = false
            }
          }
        }
        dynamic "volume" {
          for_each = kubernetes_secret.ingress_client_certificate_authority
          content {
            name = "ingress-client-secret-volume"
            secret {
              secret_name = volume.value.metadata[0].name
              optional    = false
            }
          }
        }
        volume {
          name = "ingress-nginx"
          config_map {
            name     = kubernetes_config_map.ingress[0].metadata[0].name
            optional = false
          }
        }
        volume {
          name = "static"
          config_map {
            name     = kubernetes_config_map.static[0].metadata[0].name
            optional = false
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "ingress" {
  metadata {
    name      = var.ingress.name
    namespace = var.namespace
    labels    = var.ingress.labels
  }
  spec {
    type       = var.ingress.service_type == "HeadLess" ? "ClusterIP" : var.ingress.service_type
    cluster_ip = var.ingress.service_type == "HeadLess" ? "None" : null
    selector   = var.ingress.labels
    dynamic "port" {
      for_each = var.ingress.http_port == var.ingress.grpc_port ? { http : var.ingress.http_port } : { http : var.ingress.http_port, grpc : var.ingress.grpc_port }
      content {
        name        = port.key
        target_port = local.target_ports[port.key]
        port        = var.ingress.service_type == "HeadLess" ? local.target_ports[port.key] : port.value
        protocol    = "TCP"
      }
    }
  }
}
