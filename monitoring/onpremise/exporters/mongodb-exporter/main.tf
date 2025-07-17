locals {
  # Filter out any null/empty modules and flatten the list
  valid_mongodb_modules = [for module in var.mongodb_modules : module if module != null]
  mongodb_module        = length(local.valid_mongodb_modules) > 0 ? local.valid_mongodb_modules[0][0] : null
  mongodb_env           = local.mongodb_module.env
  mongodb_env_secrets   = local.mongodb_module.env_from_secret
  mongodb_mount_secrets = local.mongodb_module.mount_secret


  # Base arguments
  base_args = [
    "--log.level=error",
    "--collector.replicasetstatus",
    "--collector.dbstats",
    "--collector.dbstatsfreestorage",
    "--collector.topmetrics",
    "--collector.currentopmetrics",
    "--collector.indexstats",
    "--collector.collstats",
    "--mongodb.uri=$(MongoDB__MonitoringConnectionString)",
    "--discovering-mode"
  ]

  # Conditionally add diagnostic data collector (We do this to work around a crash for sharded mongodb)
  diagnostic_args = var.disable_diagnostic_data != true ? ["--collector.diagnosticdata"] : []

  # TODO (This requires an init_container, might not be worth it..): if the URI starts with mongodb+srv then split the cluster otherwise check if force_split_cluster is true
  split_cluster_args = var.force_split_cluster == true ? ["--split-cluster"] : []

  args = concat(
    local.base_args,
    local.diagnostic_args,
    local.split_cluster_args
  )
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
          dynamic "volume_mount" {
            for_each = local.mongodb_mount_secrets
            content {
              mount_path = volume_mount.value.path
              name       = volume_mount.key
              read_only  = true
            }
          }

          args = local.args
        }

        dynamic "volume" {
          for_each = local.mongodb_mount_secrets
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
