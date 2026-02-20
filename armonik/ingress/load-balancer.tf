resource "kubernetes_deployment" "load_balancer" {
  count = var.load_balancer != null ? 1 : 0
  metadata {
    name        = "${local.prefix}load-balancer"
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
        name        = "${local.prefix}load-balancer"
        namespace   = var.namespace
        labels      = var.load_balancer.labels
        annotations = var.load_balancer.annotations
      }
      spec {
        node_selector  = var.load_balancer.node_selector
        restart_policy = "Always" # Always, OnFailure, Never
        dynamic "toleration" {
          for_each = var.load_balancer.node_selector
          content {
            key      = toleration.key
            operator = "Equal"
            value    = toleration.value
            effect   = "NoSchedule"
          }
        }
        dynamic "image_pull_secrets" {
          for_each = can(coalesce(var.load_balancer.image_pull_secrets)) ? [1] : []
          content {
            name = var.load_balancer.image_pull_secrets
          }
        }
        container {
          name              = "load-balancer"
          image             = can(coalesce(var.load_balancer.tag)) ? "${var.load_balancer.image}:${var.load_balancer.tag}" : var.load_balancer.image
          image_pull_policy = var.load_balancer.image_pull_policy
          args              = ["-c", "/conf/lb.yml"]
          resources {
            limits   = var.load_balancer.limits
            requests = var.load_balancer.requests
          }
          port {
            name           = "grpc"
            container_port = var.load_balancer.conf.listen_port
          }
          dynamic "env_from" {
            for_each = can(coalesce(var.load_balancer.extra_env)) ? [1] : []
            content {
              config_map_ref {
                name = kubernetes_config_map.extra_env[0].metadata[0].name
              }
            }
          }
          volume_mount {
            name       = "cluster-certs"
            mount_path = "/cluster-certs"
            read_only  = true
          }
          volume_mount {
            name       = "lb-conf"
            mount_path = "/conf"
            read_only  = true
          }
          # dynamic "volume_mount" {
          #   for_each = kubernetes_secret.load_balancer_certs
          #   content {
          #     name       = "lb-certs"
          #     mount_path = "/certs"
          #     read_only  = true
          #   }
          # }
        }
        volume {
          name = "cluster-certs"
          secret {
            secret_name = kubernetes_secret.cluster_certs[0].metadata[0].name
            optional    = false
          }
        }
        volume {
          name = "lb-conf"
          config_map {
            name = kubernetes_config_map.load_balancer_conf[0].metadata[0].name
          }
        }
        # dynamic "volume" {
        #   for_each = kubernetes_secret.load_balancer_certs
        #   content {
        #     name = "lb-certs"
        #     secret {
        #       secret_name = volume.value.metadata[0].name
        #       optional    = false
        #     }
        #   }
        # }
      }
    }
  }
}

resource "kubernetes_service" "load_balancer" {
  count = var.load_balancer != null ? 1 : 0
  metadata {
    name        = "${local.prefix}load-balancer"
    namespace   = var.namespace
    labels      = var.load_balancer.labels
    annotations = var.load_balancer.service.annotations
  }
  spec {
    type       = var.load_balancer.service.type == "HeadLess" ? "ClusterIP" : var.load_balancer.service.type
    cluster_ip = var.load_balancer.service.type == "HeadLess" ? "None" : null
    selector   = var.load_balancer.labels
    port {
      name        = "grpc"
      port        = var.load_balancer.service.type == "HeadLess" ? var.load_balancer.conf.listen_port : 8080
      target_port = var.load_balancer.conf.listen_port
      protocol    = "TCP"
    }
  }
}
