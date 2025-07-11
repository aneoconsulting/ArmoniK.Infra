locals {
  http_port = var.ingress.tls ? 8443 : 8080
  grpc_port = var.ingress.tls ? 9443 : 9080

  ports = [
    {
      name           = "ingress-p-http"
      container_port = local.http_port
    },
    {
      name           = "ingress-p-grpc"
      container_port = local.grpc_port
    }
  ]
}

# Ingress deployment
resource "kubernetes_deployment" "ingress" {
  count = var.ingress != null ? 1 : 0

  metadata {
    name      = kubernetes_service.ingress[0].metadata[0].name
    namespace = kubernetes_service.ingress[0].metadata[0].namespace
    labels = {
      app     = kubernetes_service.ingress[0].metadata[0].labels.app
      service = kubernetes_service.ingress[0].metadata[0].labels.service
    }
  }
  spec {
    replicas = var.ingress.replicas
    selector {
      match_labels = {
        app     = kubernetes_service.ingress[0].metadata[0].labels.app
        service = kubernetes_service.ingress[0].metadata[0].labels.service
      }
    }
    template {
      metadata {
        name      = kubernetes_service.ingress[0].metadata[0].name
        namespace = var.namespace
        labels = {
          app     = kubernetes_service.ingress[0].metadata[0].labels.app
          service = kubernetes_service.ingress[0].metadata[0].labels.service
        }
        annotations = local.ingress_annotations
      }
      spec {
        node_selector = local.ingress_node_selector
        dynamic "toleration" {
          for_each = (local.ingress_node_selector != {} ? [
            for index in range(0, length(local.ingress_node_selector_keys)) : {
              key   = local.ingress_node_selector_keys[index]
              value = local.ingress_node_selector_values[index]
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
          image             = var.ingress.tag != "" ? "${var.ingress.image}:${var.ingress.tag}" : var.ingress.image
          image_pull_policy = var.ingress.image_pull_policy
          resources {
            limits   = var.ingress.limits
            requests = var.ingress.requests
          }
          dynamic "port" {
            for_each = local.ports
            content {
              name           = port.value.name
              container_port = port.value.container_port
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.ingress[0].metadata[0].name
            }
          }
          volume_mount {
            name       = "ingress-secret-volume"
            mount_path = "/ingress"
            read_only  = true
          }
          volume_mount {
            name       = "ingress-client-secret-volume"
            mount_path = "/ingressclient"
            read_only  = true
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
        volume {
          name = "ingress-secret-volume"
          secret {
            secret_name = kubernetes_secret.ingress_certificate.metadata[0].name
            optional    = false
          }
        }
        volume {
          name = "ingress-client-secret-volume"
          secret {
            secret_name = kubernetes_secret.ingress_client_certificate_authority.metadata[0].name
            optional    = false
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

# Control plane service
resource "kubernetes_service" "ingress" {
  count = var.ingress != null ? 1 : 0

  metadata {
    name      = "ingress"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      service = "ingress"
    }
  }
  spec {
    type       = var.ingress.service_type == "HeadLess" ? "ClusterIP" : var.ingress.service_type
    cluster_ip = var.ingress.service_type == "HeadLess" ? "None" : null
    selector = {
      app     = "armonik"
      service = "ingress"
    }
    dynamic "port" {
      for_each = var.ingress.http_port == var.ingress.grpc_port ? [var.ingress.http_port] : [var.ingress.http_port, var.ingress.grpc_port]
      content {
        name        = "ingress-port-${port.key}"
        target_port = local.ports[port.key].container_port
        port        = var.ingress.service_type == "HeadLess" ? local.ports[port.key].container_port : port.value
        protocol    = "TCP"
      }
    }
  }
}