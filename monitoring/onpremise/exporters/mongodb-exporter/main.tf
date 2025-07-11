locals {
  mongodb_uri = var.mongo_url != "" ? var.mongo_url : try(data.kubernetes_secret.mongodb_monitoring_connection_string.data["uri"], "")
  should_split_cluster = var.force_split_cluster ? true : startswith(local.mongodb_uri, "mongodb+srv")
  args = concat(
    [
      "--log.level=error",
      "--collector.diagnosticdata",
      "--collector.replicasetstatus",
      "--collector.dbstats",
      "--collector.dbstatsfreestorage",
      "--collector.topmetrics",
      "--collector.currentopmetrics",
      "--collector.indexstats",
      "--collector.collstats",
      "--discovering-mode",
      "--mongodb.uri=${local.mongodb_uri}"
    ],
    local.should_split_cluster ? ["--split-cluster"] : []
  )
}

data "kubernetes_secret" "mongodb_monitoring_connection_string" {
  metadata {
    name      = "mongodb-monitoring-connection-string"
    namespace = var.namespace
  }
}


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
            value = local.mongodb_uri
          }

          dynamic "volume_mount" {
            for_each = var.certif_mount
            content {
              mount_path = volume_mount.value.path
              name       = volume_mount.value.secret
              read_only  = true
            }
          }

          args = local.args
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
