#Aggragation
module "partition_metrics_exporter_aggregation" {
  source    = "../../../../utils/aggregator"
  conf_list = concat([module.partition_exporter_aggregation, var.conf])
}

# Partition metrics exporter deployment
resource "kubernetes_deployment" "partition_metrics_exporter" {
  metadata {
    name      = "partition-metrics-exporter"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      type    = "monitoring"
      service = "partition-metrics-exporter"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "armonik"
        type    = "monitoring"
        service = "partition-metrics-exporter"
      }
    }
    template {
      metadata {
        name      = "partition-metrics-exporter"
        namespace = var.namespace
        labels = {
          app     = "armonik"
          type    = "monitoring"
          service = "partition-metrics-exporter"
        }
      }
      spec {
        node_selector = var.node_selector
        dynamic "toleration" {
          for_each = (var.node_selector != {} ? [
            for index in range(0, length(local.node_selector_keys)) : {
              key   = local.node_selector_keys[index]
              value = local.node_selector_values[index]
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
          for_each = (var.docker_image.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.docker_image.image_pull_secrets
          }
        }
        container {
          name              = "partition-metrics-exporter"
          image             = var.docker_image.tag != "" ? "${var.docker_image.image}:${var.docker_image.tag}" : var.docker_image.image
          image_pull_policy = "IfNotPresent"
          port {
            name           = "metrics"
            container_port = 1080
          }
          dynamic "env_from" {
            for_each = module.partition_exporter_aggregation.env_configmap
            content {
              config_map_ref {
                name = env_from.value
              }
            }
          }
          #env from config
          dynamic "env" {
            for_each = module.partition_exporter_aggregation.env
            content {
              name  = env.key
              value = env.value
            }
          }
          #env secret from config
          dynamic "env_from" {
            for_each = module.partition_exporter_aggregation.env_secret
            content {
              secret_ref {
                name = env_from.value
              }
            }
          }
          #env from secret
          dynamic "env" {
            for_each = module.partition_exporter_aggregation.env_from_secret
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
          dynamic "env_from" {
            for_each = module.partition_exporter_aggregation.env_configmap
            content {
              config_map_ref {
                name = env_from.value
              }
            }
          }
          #mount from conf
          dynamic "volume_mount" {
            for_each = module.partition_exporter_aggregation.mount_secret
            content {
              mount_path = volume_mount.value.path
              name       = volume_mount.value.secret
              read_only  = true
            }
          }
        }
        #form conf
        dynamic "volume" {
          for_each = module.partition_exporter_aggregation.mount_secret
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

# Control plane service
resource "kubernetes_service" "partition_metrics_exporter" {
  metadata {
    name      = kubernetes_deployment.partition_metrics_exporter.metadata[0].name
    namespace = kubernetes_deployment.partition_metrics_exporter.metadata[0].namespace
    labels = {
      app     = kubernetes_deployment.partition_metrics_exporter.metadata[0].labels.app
      service = kubernetes_deployment.partition_metrics_exporter.metadata[0].labels.service
    }
  }
  spec {
    type = var.service_type
    selector = {
      app     = kubernetes_deployment.partition_metrics_exporter.metadata[0].labels.app
      service = kubernetes_deployment.partition_metrics_exporter.metadata[0].labels.service
    }
    port {
      name        = kubernetes_deployment.partition_metrics_exporter.spec[0].template[0].spec[0].container[0].port[0].name
      port        = 9420
      target_port = 1080
      protocol    = "TCP"
    }
  }
}
