locals {
  # Filter out any null/empty modules and flatten the list
  valid_mongodb_modules = [for module in var.mongodb_modules : module if module != null]
  
  mongodb_env                 = length(local.valid_mongodb_modules) > 0 ? merge([for element in local.valid_mongodb_modules : element.env]...) : {}
  mongodb_env_secrets         = length(local.valid_mongodb_modules) > 0 ? merge([for element in local.valid_mongodb_modules : element.env_from_secret]...) : {}
  mongodb_mount_secrets       = length(local.valid_mongodb_modules) > 0 ? merge([for element in local.valid_mongodb_modules : element.mount_secret]...) : {}
  mongodb_cafile              = try(local.mongodb_env["MongoDB__CAFile"], "")
  certif_mount                = local.mongodb_mount_secrets
  
  # Get the monitoring connection string secret details
  monitoring_connection_secret = try(local.mongodb_env_secrets["MongoDB__MonitoringConnectionString"], null)
  
  args = [
    "--log.level=error",
    "--collector.diagnosticdata",
    "--collector.replicasetstatus",
    "--collector.dbstats",
    "--collector.dbstatsfreestorage",
    "--collector.topmetrics",
    "--collector.currentopmetrics",
    "--collector.indexstats",
    "--collector.collstats",
    "--discovering-mode"
  ]

  # TODO: add option to --split-cluster if mongodb+src

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

          # Environment variables from regular env output
          dynamic "env" {
            for_each = local.mongodb_env
            content {
              name  = env.key
              value = env.value
            }
          }

          # Environment variables from secrets
          dynamic "env" {
            for_each = local.mongodb_env_secrets
            content {
              name = env.key
              value_from {
                secret_key_ref {
                  name = env.value.secret
                  key  = env.value.field
                }
              }
            }
          }

          # Special handling for MONGODB_URI environment variable
          dynamic "env" {
            for_each = local.monitoring_connection_secret != null ? [local.monitoring_connection_secret] : []
            content {
              name = "MONGODB_URI"
              value_from {
                secret_key_ref {
                  name = env.value.secret
                  key  = env.value.field
                }
              }
            }
          }
          
          dynamic "volume_mount" {
            for_each = local.certif_mount
            content {
              mount_path = volume_mount.value.path
              name       = volume_mount.key
              read_only  = true
            }
          }

          args = local.args
        }

        dynamic "volume" {
          for_each = local.certif_mount
          content {
            name = volume.key
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