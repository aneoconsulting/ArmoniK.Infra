# Nginx Ingress deployment
resource "kubernetes_deployment" "ingress" {
  metadata {
    name      = var.nginx.name
    namespace = var.namespace
    labels    = var.nginx.labels
  }
  spec {
    replicas = var.nginx.replicas
    selector {
      match_labels = var.nginx.labels
    }
    template {
      metadata {
        name        = var.nginx.name
        namespace   = var.namespace
        labels      = var.nginx.labels
        annotations = var.nginx.annotations
      }
      spec {
        node_selector = var.nginx.node_selector
        dynamic "toleration" {
          for_each = (var.nginx.node_selector != {} ? [
            for key, value in var.nginx.node_selector : {
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
          for_each = (var.nginx.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.nginx.image_pull_secrets
          }
        }
        restart_policy = "Always" # Always, OnFailure, Never
        # Control plane container
        container {
          name              = var.nginx.name
          image             = can(try(coalesce(var.nginx.tag))) ? "${var.nginx.image}:${var.nginx.tag}" : var.nginx.image
          image_pull_policy = var.nginx.image_pull_policy
          resources {
            limits   = var.nginx.limits
            requests = var.nginx.requests
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
              name = kubernetes_config_map.nginx[0].metadata[0].name
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
            name     = kubernetes_config_map.nginx[0].metadata[0].name
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
    name        = var.nginx.name
    namespace   = var.namespace
    labels      = var.nginx.labels
    annotations = var.nginx.service.annotations
  }
  spec {
    type       = var.nginx.service.type == "HeadLess" ? "ClusterIP" : var.nginx.service.type
    cluster_ip = var.nginx.service.type == "HeadLess" ? "None" : null
    selector   = var.nginx.labels
    dynamic "port" {
      for_each = var.nginx.http_port == var.nginx.grpc_port ? { http : var.nginx.http_port } : { http : var.nginx.http_port, grpc : var.nginx.grpc_port }
      content {
        name        = port.key
        target_port = local.target_ports[port.key]
        port        = var.nginx.service.type == "HeadLess" ? local.target_ports[port.key] : port.value
        protocol    = "TCP"
      }
    }
  }
}
