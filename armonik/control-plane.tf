# Control plane deployment
resource "kubernetes_deployment" "control_plane" {
  metadata {
    name      = "control-plane"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      service = "control-plane"
    }
  }
  spec {
    replicas = var.control_plane.replicas
    selector {
      match_labels = {
        app     = "armonik"
        service = "control-plane"
      }
    }
    template {
      metadata {
        name      = "control-plane"
        namespace = var.namespace
        labels = {
          app     = "armonik"
          service = "control-plane"
        }
        annotations = local.control_plane_annotations
      }
      spec {
        node_selector = local.control_plane_node_selector
        dynamic "toleration" {
          for_each = (local.control_plane_node_selector != {} ? [
            for index in range(0, length(local.control_plane_node_selector_keys)) : {
              key   = local.control_plane_node_selector_keys[index]
              value = local.control_plane_node_selector_values[index]
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
          for_each = (var.control_plane.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.control_plane.image_pull_secrets
          }
        }
        #form conf
        dynamic "volume" {
          for_each = module.control_plane_aggregation.mount_secret
          content {
            name = volume.value.secret
            secret {
              secret_name  = volume.value.secret
              default_mode = volume.value.mode

            }
          }
        }

        dynamic "volume" {
          for_each = module.control_plane_aggregation.mount_configmap
          content {
            name = volume.value.configmap
            config_map {
              name         = volume.value.configmap
              default_mode = volume.value.mode
              dynamic "items" {
                for_each = lookup(volume.value, "items", {})
                content {
                  key  = items.key
                  path = items.value.field
                  mode = items.value.mode
                }
              }
            }
          }
        }
        restart_policy       = "Always" # Always, OnFailure, Never
        service_account_name = var.control_plane.service_account_name
        # Control plane container
        container {
          name              = var.control_plane.name
          image             = var.control_plane.tag != "" ? "${var.control_plane.image}:${var.control_plane.tag}" : var.control_plane.image
          image_pull_policy = var.control_plane.image_pull_policy
          resources {
            limits   = var.control_plane.limits
            requests = var.control_plane.requests
          }
          port {
            name           = "control-port"
            container_port = 1080
          }
          port {
            name           = "metrics-port"
            container_port = 1081
          }
          liveness_probe {
            http_get {
              path = "/liveness"
              port = 1081
            }
            initial_delay_seconds = 15
            period_seconds        = 5
            timeout_seconds       = 1
            success_threshold     = 1
            failure_threshold     = 1
          }
          startup_probe {
            http_get {
              path = "/startup"
              port = 1081
            }
            initial_delay_seconds = 1
            period_seconds        = 3
            timeout_seconds       = 1
            success_threshold     = 1
            failure_threshold     = 20
            # the pod has (period_seconds x failure_threshold) seconds to finalize its startup
          }
          #env from config
          dynamic "env" {
            for_each = module.control_plane_aggregation.env
            content {
              name  = env.key
              value = env.value
            }
          }
          #env secret from config
          dynamic "env_from" {
            for_each = module.control_plane_aggregation.env_secret
            content {
              secret_ref {
                name = env_from.value
              }
            }
          }
          #env from secret
          dynamic "env" {
            for_each = module.control_plane_aggregation.env_from_secret
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
            for_each = module.control_plane_aggregation.env_from_configmap
            content {
              name = env.key
              value_from {
                config_map_key_ref {
                  name = env.value.configmap
                  key  = env.value.field
                }
              }
            }
          }
          dynamic "env_from" {
            for_each = module.control_plane_aggregation.env_configmap
            content {
              config_map_ref {
                name = env_from.value
              }
            }
          }

          #mount from conf
          dynamic "volume_mount" {
            for_each = module.control_plane_aggregation.mount_secret
            content {
              mount_path = volume_mount.value.path
              name       = volume_mount.value.secret
              read_only  = true
            }
          }

          dynamic "volume_mount" {
            for_each = module.control_plane_aggregation.mount_configmap
            content {
              name       = volume.value.configmap
              mount_path = volume.value.path
              sub_path   = lookup(volume.value, "subpath", null)
              read_only  = true
            }
          }
        }

        # Fluent-bit container
        dynamic "container" {
          for_each = (!var.fluent_bit.is_daemonset ? [1] : [])
          content {
            name              = var.fluent_bit.container_name
            image             = "${var.fluent_bit.image}:${var.fluent_bit.tag}"
            image_pull_policy = "IfNotPresent"
            env_from {
              config_map_ref {
                name = var.fluent_bit.configmaps.envvars
              }
            }
            # Please don't change below read-only permissions
            dynamic "volume_mount" {
              for_each = local.fluent_bit_volumes
              content {
                name       = volume_mount.key
                mount_path = volume_mount.value.mount_path
                read_only  = volume_mount.value.read_only
              }
            }
          }
        }
        dynamic "volume" {
          for_each = local.fluent_bit_volumes
          content {
            name = volume.key
            dynamic "host_path" {
              for_each = (volume.value.type == "host_path" ? [1] : [])
              content {
                path = volume.value.mount_path
              }
            }
            dynamic "config_map" {
              for_each = (volume.value.type == "config_map" ? [1] : [])
              content {
                name = var.fluent_bit.configmaps.config
              }
            }
          }
        }

        # Fluent-bit container windows
        dynamic "container" {
          for_each = (!var.fluent_bit.windows_is_daemonset ? [1] : [])
          content {
            name              = var.fluent_bit.windows_container_name
            image             = "${var.fluent_bit.windows_image}:${var.fluent_bit.windows_tag}"
            image_pull_policy = "IfNotPresent"
            command           = ["powershell", "-ExecutionPolicy", "Bypass", "-File", "C:/fluent-bit/entrypoint.ps1"]
            env_from {
              config_map_ref {
                name = var.fluent_bit.windows_configmaps.envvars
              }
            }
            # Please don't change below read-only permissions
            dynamic "volume_mount" {
              for_each = local.fluent_bit_windows_volumes
              content {
                name       = volume_mount.key
                mount_path = volume_mount.value.mount_path
                sub_path   = try(volume_mount.value.sub_path, "")
                read_only  = volume_mount.value.read_only
              }
            }
          }
        }
        dynamic "volume" {
          for_each = local.fluent_bit_windows_volumes
          content {
            name = volume.key
            dynamic "host_path" {
              for_each = (volume.value.type == "host_path" ? [1] : [])
              content {
                path = volume.value.mount_path
              }
            }
            dynamic "config_map" {
              for_each = (volume.value.type == "config_map" ? [1] : [])
              content {
                name = volume.value.content

              }
            }
          }
        }
      }
    }
  }
}

# Control plane service
resource "kubernetes_service" "control_plane" {
  metadata {
    name      = kubernetes_deployment.control_plane.metadata[0].name
    namespace = kubernetes_deployment.control_plane.metadata[0].namespace
    labels = {
      app     = kubernetes_deployment.control_plane.metadata[0].labels.app
      service = kubernetes_deployment.control_plane.metadata[0].labels.service
    }
    annotations = var.control_plane.annotations
  }
  spec {
    type       = var.control_plane.service_type == "HeadLess" ? "ClusterIP" : var.control_plane.service_type
    cluster_ip = var.control_plane.service_type == "HeadLess" ? "None" : null
    selector = {
      app     = kubernetes_deployment.control_plane.metadata[0].labels.app
      service = kubernetes_deployment.control_plane.metadata[0].labels.service
    }
    port {
      name        = kubernetes_deployment.control_plane.spec[0].template[0].spec[0].container[0].port[0].name
      port        = var.control_plane.service_type == "HeadLess" ? kubernetes_deployment.control_plane.spec[0].template[0].spec[0].container[0].port[0].container_port : var.control_plane.port
      target_port = kubernetes_deployment.control_plane.spec[0].template[0].spec[0].container[0].port[0].container_port
      protocol    = "TCP"
    }
  }
}
