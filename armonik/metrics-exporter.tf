#Aggragation
module "metrics_aggregation" {
  source    = "../utils/aggregator"
  conf_list = concat([module.core_aggregation], var.metrics_exporter.conf)
}
# Metrics exporter deployment
resource "kubernetes_deployment" "metrics_exporter" {
  metadata {
    name      = var.metrics_exporter.name
    namespace = var.namespace
    labels = {
      app     = var.metrics_exporter.label_app
      type    = "monitoring"
      service = var.metrics_exporter.label_service
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = var.metrics_exporter.label_app
        type    = "monitoring"
        service = var.metrics_exporter.label_service
      }
    }
    template {
      metadata {
        name      = "metrics-exporter"
        namespace = var.namespace
        labels = {
          app     = var.metrics_exporter.label_app
          type    = "monitoring"
          service = var.metrics_exporter.label_service
        }
      }
      spec {
        node_selector = var.metrics_exporter.node_selector
        dynamic "toleration" {
          for_each = (var.metrics_exporter.node_selector != {} ? [
            for index in range(0, length(local.metrics_exporter.node_selector_keys)) : {
              key   = local.metrics_exporter.node_selector_keys[index]
              value = local.metrics_exporter.node_selector_values[index]
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
          for_each = (var.metrics_exporter.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.metrics_exporter.image_pull_secrets
          }
        }
        #form conf
        dynamic "volume" {
          for_each = module.metrics_aggregation.mount_secret
          content {

            name = volume.value.secret
            secret {
              secret_name  = volume.value.secret
              default_mode = volume.value.mode

            }
          }
        }
        container {
          name              = var.metrics_exporter.name
          image             = var.metrics_exporter.tag != "" ? "${var.metrics_exporter.image}:${var.metrics_exporter.tag}" : var.metrics_exporter.image
          image_pull_policy = var.metrics_exporter.image_pull_policy
          port {
            name           = var.metrics_exporter.port_name
            container_port = var.metrics_exporter.target_port
          }

          dynamic "env_from" {
            for_each = module.metrics_aggregation.env_configmap
            content {
              config_map_ref {
                name = env_from.value
              }
            }
          }
          #env from config
          dynamic "env" {
            for_each = module.metrics_aggregation.env
            content {
              name  = env.key
              value = env.value
            }
          }
          #env secret from config
          dynamic "env_from" {
            for_each = module.metrics_aggregation.env_secret
            content {
              secret_ref {
                name = env_from.value
              }
            }
          }
          #env from secret
          dynamic "env" {
            for_each = module.metrics_aggregation.env_from_secret
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
          dynamic "env" {
            for_each = var.extra_conf.metrics
            content {
              name  = env.key
              value = env.value
            }
          }
          #mount from conf
          dynamic "volume_mount" {
            for_each = module.metrics_aggregation.mount_secret
            content {
              mount_path = volume_mount.value.path
              name       = volume_mount.value.secret
              read_only  = true
            }
          }
        }
      }
    }
  }
}
