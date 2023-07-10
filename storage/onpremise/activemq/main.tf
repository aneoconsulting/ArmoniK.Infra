# ActiveMQ is deployed as a service in Kubernetes create-cluster

# Kubernetes ActiveMQ deployment
resource "kubernetes_deployment" "activemq" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      app     = "storage"
      type    = "queue"
      service = var.name
    }
  }
  spec {
    replicas                  = 1
    min_ready_seconds         = var.min_ready_seconds
    revision_history_limit    = var.revision_history_limit
    progress_deadline_seconds = var.progress_deadline_seconds

    strategy {
      type = var.strategy_update
      dynamic "rolling_update" {
        for_each = flatten([var.rolling_update])
        content {
          max_surge       = lookup(rolling_update.value, "max_surge", "25%")
          max_unavailable = lookup(rolling_update.value, "max_unavailable", "25%")
        }
      }
    }
    selector {
      match_labels = {
        app     = "storage"
        type    = "queue"
        service = var.name
      }
    }
    template {
      metadata {
        name = var.name
        labels = {
          app     = "storage"
          type    = "queue"
          service = var.name
        }
      }
      spec {
        termination_grace_period_seconds = var.termination_grace_period_seconds
        priority_class_name              = var.priority_class_name
        node_selector                    = var.node_selector
        restart_policy                   = var.restart_policy
        node_name                        = var.node_name
        active_deadline_seconds          = var.active_deadline_seconds
        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secrets
          content {
            name = image_pull_secrets.value
          }
        }
        dynamic "toleration" {
          for_each = var.toleration
          content {
            effect             = lookup(toleration.value, "effect", null)
            key                = lookup(toleration.value, "key", local.node_selector_keys[index])
            operator           = lookup(toleration.value, "operator", null)
            toleration_seconds = lookup(toleration.value, "toleration_seconds", null)
            value              = lookup(toleration.value, "value", local.node_selector_values[index])
          }
        }

        dynamic "security_context" {
          for_each = flatten([var.security_context])
          content {
            fs_group        = lookup(security_context.value, "fs_group", null)
            run_as_group    = lookup(security_context.value, "run_as_group", null)
            run_as_user     = lookup(security_context.value, "run_as_user", null)
            run_as_non_root = lookup(security_context.value, "run_as_non_root", null)
          }
        }

        container {
          name              = "activemq"
          image             = "${var.image}:${var.tag}"
          image_pull_policy = "IfNotPresent"
          volume_mount {
            name       = "activemq-storage-secret-volume"
            mount_path = "/credentials/"
            read_only  = true
          }
          volume_mount {
            name       = "activemq-jetty-xml"
            mount_path = "/opt/activemq/conf/"
            read_only  = true
          }
          volume_mount {
            name       = "activemq-jolokia-xml"
            mount_path = "/opt/activemq/webapps/api/WEB-INF/classes/"
            read_only  = true
          }
          port {
            name           = "amqp"
            container_port = 5672
            protocol       = "TCP"
          }
          port {
            name           = "dashboard"
            container_port = 8161
            protocol       = "TCP"
          }
        }
        volume {
          name = "activemq-storage-secret-volume"
          secret {
            secret_name = kubernetes_secret.activemq_certificate.metadata[0].name
            optional    = false
          }
        }
        volume {
          name = "activemq-jetty-xml"
          config_map {
            name     = kubernetes_config_map.activemq_configs.metadata[0].name
            optional = false
          }
        }
        volume {
          name = "activemq-jolokia-xml"
          config_map {
            name     = kubernetes_config_map.activemq_jolokia_configs.metadata[0].name
            optional = false
          }
        }
      }
    }
  }
}

# Kubernetes ActiveMQ service
resource "kubernetes_service" "activemq" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      app     = "storage"
      type    = "queue"
      service = "activemq"
    }
  }
  spec {
    type = "ClusterIP"
    selector = {
      app     = "storage"
      type    = "queue"
      service = var.name
    }
    port {
      name        = "amqp"
      port        = 5672
      target_port = 5672
      protocol    = "TCP"
    }
    port {
      name        = "dashboard"
      port        = 8161
      target_port = 8161
      protocol    = "TCP"
    }
  }
}
