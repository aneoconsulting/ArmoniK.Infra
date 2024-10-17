resource "kubernetes_deployment" "mongodb_exporter" {
  metadata {
    name      = "mongodb-metrics-exporter"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      type    = "monitoring"
      service = "mongodb-metrics-exporter"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "armonik"
        type    = "monitoring"
        service = "mongodb-metrics-exporter"
      }
    }

    template {
      metadata {
        name      = "mongodb-metrics-exporter"
        namespace = var.namespace
        labels = {
          app     = "armonik"
          type    = "monitoring"
          service = "mongodb-metrics-exporter"
        }
      }
      spec {
        container {
          name  = "mongodb-metrics-exporter"
          image = var.docker_image.tag != "" ? "${var.docker_image.image}:${var.docker_image.tag}" : var.docker_image.image

          env {
            name  = "MONGODB_URI"
            value = var.mongo_url
          }

          dynamic "volume_mount" {
            for_each = var.certif_mount
            content {
              mount_path = volume_mount.value.path
              name       = volume_mount.value.secret
              read_only  = true
            }
          }

          args = ["--log.level=error", "--collector.diagnosticdata", "--collector.replicasetstatus", "--collector.dbstats", "--collector.dbstatsfreestorage", "--collector.topmetrics", "--collector.currentopmetrics", "--collector.indexstats", "--collector.collstats", "--discovering-mode", "--mongodb.uri=$(MONGODB_URI)"]
        }

        dynamic "volume" {
          for_each = var.certif_mount
          content {
            name = volume.value.secret
            secret {
              secret_name  = volume.value.secret
              default_mode = volume.value.mode
            }
          }
        }

      }
    }
  }
}

resource "kubernetes_service" "mongodb_exporter_service" {
  metadata {
    name      = "mongodb-metrics-exporter"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      type    = "monitoring"
      service = "mongodb-metrics-exporter"
    }
  }

  spec {
    selector = {
      app     = "armonik"
      type    = "monitoring"
      service = "mongodb-metrics-exporter"
    }

    port {
      port        = 9216
      target_port = 9216
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
