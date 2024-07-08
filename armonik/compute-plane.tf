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
            for_each = merge([for element in each.value.polling_agent.conf : element.env]...)
            content {
              name  = env.key
              value = env.value
            }
          }
          #env secret from config
          dynamic "env_from" {
            for_each = setunion([for element in each.value.polling_agent.conf : element.env_secret]...)
            content {
              secret_ref {
                name = env_from.value
              }
            }
          }
          dynamic "env_from" {
            for_each = local.polling_agent_configmaps
            content {
              config_map_ref {
                name = env_from.value
              }
            }
          }
          dynamic "env" {
            for_each = local.supported_queues
            content {
              name  = env.value
              value = each.key
            }
          }
          dynamic "env" {
            for_each = local.credentials
            content {
              name = env.key
              value_from {
                secret_key_ref {
                  key      = env.value.key
                  name     = env.value.name
                  optional = false
                }
              }
            }
          }
          volume_mount {
            name       = "cache-volume"
            mount_path = "/cache"
          }
          dynamic "volume_mount" {
            for_each = local.object_storage_adapter == "ArmoniK.Adapters.LocalStorage.ObjectStorage" ? [1] : []
            content {
              name       = "nfs"
              mount_path = local.local_storage_mount_path
            }
          }
          dynamic "volume_mount" {
            for_each = local.certificates
            content {
              name       = volume_mount.value.name
              mount_path = volume_mount.value.mount_path
              read_only  = true
            }
          }
        }
        dynamic "volume" {
          for_each = local.object_storage_adapter == "ArmoniK.Adapters.LocalStorage.ObjectStorage" ? [1] : []
          content {
            name = "nfs"
            persistent_volume_claim {
              claim_name = var.pvc_name
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
            dynamic "env_from" {
              for_each = local.worker_configmaps
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
          for_each = (local.file_storage_type == "nfs" ? [1] : [])
          content {
            name = "shared-volume"
            nfs {
              path      = data.kubernetes_secret.shared_storage.data.host_path
              server    = data.kubernetes_secret.shared_storage.data.file_server_ip
              read_only = true
            }
          }
        }
        dynamic "volume" {
          for_each = (local.file_storage_type == "hostpath" ? [1] : [])
          content {
            name = "shared-volume"
            host_path {
              path = data.kubernetes_secret.shared_storage.data.host_path
              type = "Directory"
            }
          }
        }
        dynamic "volume" {
          for_each = local.certificates
          content {
            name = volume.value.name
            secret {
              secret_name = volume.value.secret_name
              optional    = false
            }
          }
        }
        # Fluent-bit container
        dynamic "container" {
          for_each = (!data.kubernetes_secret.fluent_bit.data.is_daemonset ? [1] : [])
          content {
            name              = data.kubernetes_secret.fluent_bit.data.name
            image             = "${data.kubernetes_secret.fluent_bit.data.image}:${data.kubernetes_secret.fluent_bit.data.tag}"
            image_pull_policy = "IfNotPresent"
            env_from {
              config_map_ref {
                name = data.kubernetes_secret.fluent_bit.data.envvars
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
                name = data.kubernetes_secret.fluent_bit.data.config
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
