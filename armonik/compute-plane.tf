#Aggragation
module "worker_aggregation" {
  source    = "../utils/aggregator"
  for_each  = var.compute_plane
  conf_list = flatten([module.worker_all_aggregation, each.value.worker[0].conf])
}

module "polling_agent_aggregation" {
  source   = "../utils/aggregator"
  for_each = var.compute_plane
  conf_list = flatten([module.polling_all_aggregation,
    {
      env = {
        for queue in tolist(local.supported_queues) : queue => each.key
      }
  }, each.value.polling_agent.conf])
}

# Agent deployment
resource "kubernetes_deployment" "compute_plane" {
  for_each = var.compute_plane
  metadata {
    name      = "compute-plane-${each.key}"
    namespace = var.namespace
    labels = {
      app       = "armonik"
      service   = "compute-plane"
      partition = each.key
    }
  }
  spec {
    replicas = each.value.replicas
    selector {
      match_labels = {
        app       = "armonik"
        service   = "compute-plane"
        partition = each.key
      }
    }
    template {
      metadata {
        name      = "${each.key}-compute-plane"
        namespace = var.namespace
        labels = {
          app       = "armonik"
          service   = "compute-plane"
          partition = each.key
        }
        annotations = local.compute_plane_annotations[each.key]
      }
      spec {
        node_selector = local.compute_plane_node_selector[each.key]
        dynamic "toleration" {
          for_each = (local.compute_plane_node_selector[each.key] != {} ? [
            for index in range(0, length(local.compute_plane_node_selector_keys[each.key])) : {
              key   = local.compute_plane_node_selector_keys[each.key][index]
              value = local.compute_plane_node_selector_values[each.key][index]
            }
          ] : [])
          content {
            key      = toleration.value.key
            operator = "Equal"
            value    = toleration.value.value
            effect   = "NoSchedule"
          }
        }
        termination_grace_period_seconds = each.value.termination_grace_period_seconds
        share_process_namespace          = false
        dynamic "image_pull_secrets" {
          for_each = (each.value.image_pull_secrets != "" ? [1] : [])
          content {
            name = each.value.image_pull_secrets
          }
        }
        #form conf
        dynamic "volume" {
          for_each = merge(module.polling_agent_aggregation[each.key].mount_secret, module.worker_aggregation[each.key].mount_secret)
          content {

            name = volume.value.secret
            secret {
              secret_name  = volume.value.secret
              default_mode = volume.value.mode

            }
          }
        }

        dynamic "volume" {
          for_each = merge(module.polling_agent_aggregation[each.key].mount_configmap, module.worker_aggregation[each.key].mount_configmap)
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
        service_account_name = each.value.service_account_name
        # Polling agent container
        container {
          name              = "polling-agent"
          image             = each.value.polling_agent.tag != "" ? "${var.compute_plane[each.key].polling_agent.image}:${var.compute_plane[each.key].polling_agent.tag}" : var.compute_plane[each.key].polling_agent.image
          image_pull_policy = each.value.polling_agent.image_pull_policy
          security_context {
            capabilities {
              drop = ["SYS_PTRACE"]
            }
          }
          resources {
            limits   = each.value.polling_agent.limits
            requests = each.value.polling_agent.requests
          }
          port {
            name           = "poll-agent-port"
            container_port = 1080
          }
          dynamic "readiness_probe" {
            for_each = each.value.readiness_probe ? [1] : []
            content {
              http_get {
                path = "/readiness"
                port = 1080
              }
              period_seconds    = 3
              timeout_seconds   = 1
              success_threshold = 1
              failure_threshold = 1
            }
          }
          liveness_probe {
            http_get {
              path = "/liveness"
              port = 1080
            }
            initial_delay_seconds = 15
            period_seconds        = 10
            timeout_seconds       = 10
            success_threshold     = 1
            failure_threshold     = 3
          }
          startup_probe {
            http_get {
              path = "/startup"
              port = 1080
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
            for_each = module.polling_agent_aggregation[each.key].env
            content {
              name  = env.key
              value = env.value
            }
          }
          #env secret from config
          dynamic "env_from" {
            for_each = module.polling_agent_aggregation[each.key].env_secret
            content {
              secret_ref {
                name = env_from.value
              }
            }
          }
          #env from secret
          dynamic "env" {
            for_each = module.polling_agent_aggregation[each.key].env_from_secret
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
            for_each = module.polling_agent_aggregation[each.key].env_from_configmap
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
            for_each = module.polling_agent_aggregation[each.key].env_configmap
            content {
              config_map_ref {
                name = env_from.value
              }
            }
          }

          volume_mount {
            name       = "cache-volume"
            mount_path = "/cache"
          }

          #mount from conf
          dynamic "volume_mount" {
            for_each = module.polling_agent_aggregation[each.key].mount_secret
            content {
              mount_path = volume_mount.value.path
              name       = volume_mount.value.secret
              read_only  = true
            }
          }

          dynamic "volume_mount" {
            for_each = module.polling_agent_aggregation[each.key].mount_configmap
            content {
              name       = volume.value.configmap
              mount_path = volume.value.path
              sub_path   = lookup(volume.value, "subpath", null)
              read_only  = true
            }
          }
        }

        # Containers of worker
        dynamic "container" {
          iterator = worker
          for_each = each.value.worker
          content {
            name              = "${worker.value.name}-${worker.key}"
            image             = worker.value.tag != "" ? "${worker.value.image}:${worker.value.tag}" : worker.value.image
            image_pull_policy = worker.value.image_pull_policy
            resources {
              limits   = worker.value.limits
              requests = worker.value.requests
            }
            lifecycle {
              pre_stop {
                exec {
                  command = ["/bin/sh", "-c", local.pre_stop_wait_script]
                }
              }
            }
            # liveness and startup probes of the worker use the endpoint of the polling agent.
            # This is effective as the polling agent query the health of the worker and forward it as its own health.
            liveness_probe {
              http_get {
                path = "/liveness"
                port = 1080
              }
              initial_delay_seconds = 15
              period_seconds        = 10
              timeout_seconds       = 10
              success_threshold     = 1
              failure_threshold     = 3
            }
            startup_probe {
              http_get {
                path = "/startup"
                port = 1080
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
              for_each = module.worker_aggregation[each.key].env
              content {
                name  = env.key
                value = env.value
              }
            }
            #env secret from config
            dynamic "env_from" {
              for_each = module.worker_aggregation[each.key].env_secret
              content {
                secret_ref {
                  name = env_from.value
                }
              }
            }
            #mount from conf
            dynamic "volume_mount" {
              for_each = module.worker_aggregation[each.key].mount_secret
              content {
                mount_path = volume_mount.value.path
                name       = volume_mount.value.secret
                read_only  = true
              }
            }

            dynamic "volume_mount" {
              for_each = module.worker_aggregation[each.key].mount_configmap
              content {
                name       = volume.value.configmap
                mount_path = volume.value.path
                sub_path   = lookup(volume.value, "subpath", null)
                read_only  = true
              }
            }

            #env from secret
            dynamic "env" {
              for_each = module.worker_aggregation[each.key].env_from_secret
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
              for_each = module.worker_aggregation[each.key].env_from_configmap
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
              for_each = module.worker_aggregation[each.key].env_configmap
              content {
                config_map_ref {
                  name = env_from.value
                }
              }
            }
            volume_mount {
              name       = "cache-volume"
              mount_path = "/cache"
            }
            dynamic "volume_mount" {
              for_each = (local.check_file_storage_type == "FS" ? [1] : [])
              content {
                name       = "shared-volume"
                mount_path = "/data"
                read_only  = true
              }
            }
          }
        }
        volume {
          name = "cache-volume"
          empty_dir {
            medium     = try(each.value.cache_config.memory ? "Memory" : null, null)
            size_limit = try(each.value.cache_config.size_limit, null)
          }
        }

        dynamic "volume" {
          for_each = (local.file_storage_type == "hostpath" ? [1] : [])
          content {
            name = "shared-volume"
            host_path {
              path = var.shared_storage_settings.host_path
              type = "Directory"
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
            lifecycle {
              pre_stop {
                exec {
                  command = ["/bin/sh", "-c", local.pre_stop_wait_script]
                }
              }
            }
            volume_mount {
              name       = "cache-volume"
              mount_path = "/cache"
              read_only  = true
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


locals {
  pre_stop_wait_script = <<EOF

while test -e /cache/armonik_agent.sock ; do
  sleep 1
done

EOF
}
