locals {
  # To ensure image pull secrets are passed as an array/list and remove null value or empty strings
  image_pull_secrets = compact(try(tolist(var.mongodb.image_pull_secrets), [tostring(var.mongodb.image_pull_secrets)]))
  arbiter_replicas   = var.sharding.shards.replicas > 1 ? 1 : 0

  configsvr_node_selector = coalesce(try(var.sharding.configsvr.node_selector, null), var.mongodb.node_selector)
  router_node_selector    = coalesce(try(var.sharding.router.node_selector, null), var.mongodb.node_selector)
  shards_node_selector    = coalesce(try(var.sharding.shards.node_selector, null), var.mongodb.node_selector)
  arbiter_node_selector   = coalesce(try(var.sharding.arbiter.node_selector, null), var.mongodb.node_selector)

  shards_labels    = try(var.labels.shardsvr, null)
  arbiter_labels   = try(var.labels.arbiter, null)
  configsvr_labels = try(var.labels.configsvr, null)
  router_labels    = try(var.labels.router, null)

  timeout = var.timeout * var.sharding.shards.quantity
}

resource "helm_release" "mongodb" {
  name       = var.name
  namespace  = var.namespace
  chart      = var.mongodb.helm_chart_name
  repository = var.mongodb.helm_chart_repository
  version    = var.mongodb.helm_chart_version
  timeout    = local.timeout

  values = [
    yamlencode({
      "commonLabels" = var.default_labels
      "shards"       = var.sharding.shards.quantity

      "image" = {
        "registry"    = var.mongodb.registry
        "repository"  = var.mongodb.image
        "tag"         = var.mongodb.tag
        "pullSecrets" = local.image_pull_secrets
      }

      "auth" = {
        "enabled" = true
      }

      "common" = {
        "podLabels"                 = var.default_labels
        "mongodbSystemLogVerbosity" = 5
        "initScriptsSecret"         = kubernetes_secret.database_init_script.metadata[0].name
        "extraEnvVarsSecret"        = kubernetes_secret.mongodb_user.metadata[0].name
        "extraVolumes" = [{
          name = "mongodb-cert"
          secret = {
            secretName = kubernetes_secret.mongodb_certificate.metadata[0].name
          }
        }]
        "extraVolumeMounts" = [{
          mountPath = "/mongodb/"
          name      = "mongodb-cert"
        }]
      }

      "volumePermissions" = {
        "resourcesPreset" = "micro"
      }

      "service" = {
        "ports.mongodb" = floor(var.mongodb.service_port)
      }

      "networkPolicy" = {
        "enabled" = true
      }

      "configsvr" = {
        "replicaCount"      = var.sharding.configsvr.replicas
        "mongodbExtraFlags" = local.mongodb_extra_flags
        "nodeSelector"      = local.configsvr_node_selector

        "tolerations" = local.configsvr_node_selector != {} ? [
          for key, value in local.configsvr_node_selector : {
            "key"   = key
            "value" = value
          }
        ] : []

        "podLabels" = local.configsvr_labels
        "resources" = var.resources.configsvr

        "persistentVolumeClaimRetentionPolicy" = {
          "enabled"     = true
          "whenDeleted" = "Delete"
        }

        "podSecurityContext" = {
          "fsGroup" = var.security_context.fs_group
        }
        "containerSecurityContext" = {
          "runAsUser"  = var.security_context.run_as_user
          "runAsGroup" = var.security_context.fs_group
        }
      }

      "mongos" = {
        "replicaCount"      = var.sharding.router.replicas
        "mongodbExtraFlags" = local.mongodb_extra_flags
        "nodeSelector"      = local.router_node_selector

        "tolerations" = local.router_node_selector != {} ? [
          for key, value in local.router_node_selector : {
            "key"   = key
            "value" = value
          }
        ] : []

        "podLabels" = local.router_labels
        "resources" = var.resources.router
      }

      "shardsvr" = {
        "dataNode" = {
          "replicaCount"      = var.sharding.shards.replicas
          "mongodbExtraFlags" = local.mongodb_extra_flags
          "nodeSelector"      = local.shards_node_selector

          "tolerations" = local.shards_node_selector != {} ? [
            for key, value in local.shards_node_selector : {
              "key"   = key
              "value" = value
            }
          ] : []

          "podLabels" = local.shards_labels
          "resources" = var.resources.shards

          "persistentVolumeClaimRetentionPolicy" = {
            "enabled"     = true
            "whenDeleted" = "Delete"
          }

          "podSecurityContext" = {
            "fsGroup" = var.security_context.fs_group
          }
          "containerSecurityContext" = {
            "runAsUser"  = var.security_context.run_as_user
            "runAsGroup" = var.security_context.fs_group
          }
        }

        "arbiter" = {
          "replicaCount"      = local.arbiter_replicas
          "mongodbExtraFlags" = local.mongodb_extra_flags
          "nodeSelector"      = local.arbiter_node_selector

          "tolerations" = local.arbiter_node_selector != {} ? [
            for key, value in local.arbiter_node_selector : {
              "key"   = key
              "value" = value
            }
          ] : []

          "extraVolumeMounts" = [{
            mountPath = "bitnami/mongodb/"
            name      = "empty-dir"
            subPath   = "app-volume-dir"
          }]

          "podLabels" = local.arbiter_labels
          "resources" = var.resources.arbiter
        }

        # "metrics" = {
        # }
      }
    })
  ]

  ### PERSISTENCE FOR DATABASE
  dynamic "set" {
    for_each = !can(coalesce(var.persistence.shards)) ? [1] : []
    content {
      name  = "shardsvr.persistence.enabled"
      value = "false"
    }
  }
  dynamic "set" {
    for_each = can(coalesce(var.persistence.shards.storage_provisioner)) ? [1] : []
    content {
      name  = "shardsvr.persistence.storageClass"
      value = kubernetes_storage_class.shards[0].metadata[0].name
    }
  }
  dynamic "set" {
    for_each = can(coalesce(var.persistence.shards)) ? [1] : []
    content {
      name  = "shardsvr.persistence.accessModes[0]"
      value = var.persistence.shards.access_mode[0]
    }
  }
  dynamic "set" {
    for_each = can(coalesce(var.persistence.shards.resources.requests.storage)) ? [1] : []
    content {
      name  = "shardsvr.persistence.size"
      value = var.persistence.shards.resources.requests.storage
    }
  }

  ### PERSISTENCE FOR CONFIG SERVER
  dynamic "set" {
    for_each = !can(coalesce(var.persistence.configsvr)) ? [1] : []
    content {
      name  = "configsvr.persistence.enabled"
      value = false
    }
  }
  dynamic "set" {
    for_each = can(coalesce(var.persistence.configsvr)) ? [1] : []
    content {
      name  = "configsvr.persistence.storageClass"
      value = kubernetes_storage_class.configsvr[0].metadata[0].name
    }
  }
  dynamic "set" {
    for_each = can(coalesce(var.persistence.configsvr)) ? [1] : []
    content {
      name  = "configsvr.persistence.accessModes[0]"
      value = var.persistence.configsvr.access_mode[0]
    }
  }
  dynamic "set" {
    for_each = can(coalesce(var.persistence.configsvr.resources.requests.storage)) ? [1] : []
    content {
      name  = "configsvr.persistence.size"
      value = var.persistence.configsvr.resources.requests.storage
    }
  }

  # Setting this explicit dependency avoids a deadlock at destruction
  depends_on = [kubernetes_storage_class.configsvr, kubernetes_storage_class.shards]
}
