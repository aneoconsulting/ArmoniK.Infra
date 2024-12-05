resource "kubernetes_daemonset" "fluent_bit" {
  count = (local.fluent_bit_is_daemonset ? 1 : 0)
  metadata {
    name      = "fluent-bit"
    namespace = var.namespace
    labels = {
      "k8s-app"                       = "fluent-bit"
      version                         = "v1"
      "kubernetes.io/cluster-service" = "true"
    }
  }
  spec {
    selector {
      match_labels = {
        "k8s-app" = "fluent-bit"
      }
    }
    template {
      metadata {
        labels = {
          "k8s-app"                       = "fluent-bit"
          version                         = "v1"
          "kubernetes.io/cluster-service" = "true"
        }
      }
      spec {
        node_selector = local.node_selector
        dynamic "toleration" {
          for_each = local.node_selector
          content {
            key      = toleration.key
            operator = "Equal"
            value    = toleration.value
            effect   = "NoSchedule"
          }
        }
        dynamic "image_pull_secrets" {
          for_each = (local.fluent_bit_image_pull_secrets != "" ? [1] : [])
          content {
            name = local.fluent_bit_image_pull_secrets
          }
        }
        container {
          name              = local.fluent_bit_container_name
          image             = "${local.fluent_bit_image}:${local.fluent_bit_tag}"
          image_pull_policy = "IfNotPresent"
          env {
            name = "HOSTNAME"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "metadata.name"
              }
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.fluent_bit_envvars_config.metadata[0].name
            }
          }
          # FIXME: use PVC instead
          # volume_mount {
          #   name       = "fluentbitstate"
          #   mount_path = "/var/fluent-bit/state"
          # }
          # Please don't change below read-only permissions
          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
            read_only  = true
          }
          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = true
          }
          volume_mount {
            name       = "runlogjournal"
            mount_path = "/run/log/journal"
            read_only  = true
          }
          volume_mount {
            name       = "dmesg"
            mount_path = "/var/log/dmesg"
            read_only  = true
          }
          volume_mount {
            name       = "fluent-bit-config"
            mount_path = "/fluent-bit/etc/"
            read_only  = true
          }
          volume_mount {
            name       = "aws-auth-config"
            mount_path = "/root/.aws"
            read_only  = true
          }
        }
        # volume {
        #   name = "fluentbitstate"
        #   host_path {
        #     path = local.fluent_bit_state_hostpath
        #   }
        # }
        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }
        volume {
          name = "varlibdockercontainers"
          host_path {
            path = local.fluent_bit_var_lib_docker_containers_hostpath
          }
        }
        volume {
          name = "runlogjournal"
          host_path {
            path = local.fluent_bit_run_log_journal_hostpath
          }
        }
        volume {
          name = "dmesg"
          host_path {
            path = "/var/log/dmesg"
          }
        }
        volume {
          name = "fluent-bit-config"
          config_map {
            name = kubernetes_config_map.fluent_bit_config.metadata[0].name
          }
        }
        volume {
          name = "aws-auth-config"
          secret {
            secret_name = kubernetes_secret.aws_auth_config.metadata[0].name
          }
        }
        host_network                     = false
        dns_policy                       = "ClusterFirstWithHostNet"
        termination_grace_period_seconds = 10
        service_account_name             = kubernetes_service_account.fluent_bit[0].metadata[0].name
        # To use kubernetes_manifest, you should have Kubernetes already installed !!
        #service_account_name = kubernetes_manifest.service_account_fluent_bit[0].manifest.metadata.name
        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        toleration {
          operator = "Exists"
          effect   = "NoExecute"
        }
        toleration {
          operator = "Exists"
          effect   = "NoSchedule"
        }
      }
    }
  }
}

resource "kubernetes_daemonset" "fluent_bit_windows" {
  count = (local.windows_and_daemonset ? 1 : 0)

  metadata {
    name      = "fluent-bit-windows"
    namespace = var.namespace
    labels = {
      "k8s-app"                       = "fluent-bit"
      version                         = "v1"
      "kubernetes.io/cluster-service" = "true"
    }
  }
  spec {
    selector {
      match_labels = {
        "k8s-app" = "fluent-bit"
      }
    }
    template {
      metadata {
        labels = {
          "k8s-app"                       = "fluent-bit"
          version                         = "v1"
          "kubernetes.io/cluster-service" = "true"
        }
      }
      spec {
        node_selector = local.node_selector_windows

        dynamic "toleration" {
          for_each = local.node_selector_windows
          content {
            key      = toleration.key
            operator = "Equal"
            value    = toleration.value
            effect   = "NoSchedule"
          }
        }
        dynamic "image_pull_secrets" {
          for_each = (local.fluent_bit_windows_image_pull_secrets != "" ? [1] : [])
          content {
            name = local.fluent_bit_windows_image_pull_secrets
          }
        }
        container {
          name              = local.fluent_bit_windows_container_name
          image             = "${local.fluent_bit_windows_image}:${local.fluent_bit_windows_tag}"
          image_pull_policy = "IfNotPresent"
          command           = ["powershell", "-ExecutionPolicy", "Bypass", "-File", "C:/fluent-bit/entrypoint.ps1"]
          env {
            name = "HOSTNAME"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "metadata.name"
              }
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.fluent_bit_envvars_config_windows.metadata[0].name
            }
          }
          volume_mount {
            name       = "varlog"
            mount_path = "C:/var/log"
            read_only  = true
          }
          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "C:/ProgramData/docker/containers"
            read_only  = true
          }
          volume_mount {
            name       = "fluent-bit-config"
            mount_path = "C:/fluent-bit/etc"
            read_only  = true
          }
          volume_mount {
            name       = "entrypoint-script"
            mount_path = "C:/fluent-bit/entrypoint.ps1"
            sub_path   = "entrypoint.ps1"
          }
        }
        volume {
          name = "varlog"
          host_path {
            path = "C:/var/log"
          }
        }
        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "C:/ProgramData/docker/containers"
          }
        }
        volume {
          name = "fluent-bit-config"
          config_map {
            name = kubernetes_config_map.fluent_bit_config_windows.metadata[0].name
          }
        }
        volume {
          name = "entrypoint-script"
          config_map {
            name = kubernetes_config_map.fluent_bit_entrypoint.metadata[0].name
          }
        }
        host_network                     = false
        dns_policy                       = "ClusterFirstWithHostNet"
        termination_grace_period_seconds = 10
        service_account_name             = kubernetes_service_account.fluent_bit_windows[0].metadata[0].name
        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        toleration {
          operator = "Exists"
          effect   = "NoExecute"
        }
        toleration {
          operator = "Exists"
          effect   = "NoSchedule"
        }
      }
    }
  }
}
