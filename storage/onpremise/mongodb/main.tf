locals {
  architecture = coalesce(var.mongodb.replicas, 0) == 0 ? "standalone" : "replicaset"
  replicas     = max(1, coalesce(var.mongodb.replicas, 0))
  # To ensure image pull secrets are passed as an array/list
  image_pull_secrets = try(tolist(var.mongodb.image_pull_secrets), [tostring(var.mongodb.image_pull_secrets)])
}

resource "helm_release" "mongodb" {
  name       = var.name
  namespace  = var.namespace
  chart      = var.mongodb.helm_chart_name
  repository = var.mongodb.helm_chart_repository
  version    = var.mongodb.helm_chart_version
  timeout    = var.timeout * (1 + local.replicas)

  values = [
    yamlencode({
      "labels"       = var.labels
      "replicaCount" = local.replicas
      "nodeSelector" = var.mongodb.node_selector

      "tolerations" = var.mongodb.node_selector != {} ? [
        for index in range(0, length(local.node_selector_keys)) : {
          key   = local.node_selector_keys[index]
          value = local.node_selector_values[index]
        }
      ] : []

      "podLabels" = var.labels
      "image" = {
        "registry"    = var.mongodb.registry
        "repository"  = var.mongodb.image
        "tag"         = var.mongodb.tag
        "pullSecrets" = local.image_pull_secrets
      }
      "architecture" = local.architecture
      "tls" = {
        "enabled"       = "true"
        "autoGenerated" = "true"
      }
      "auth" = {
        "databases" = ["database"]
      }

      "podSecurityContext" = {
        "fsGroup" = var.security_context.fs_group
      }
      "containerSecurityContext" = {
        "runAsUser"  = var.security_context.run_as_user
        "runAsGroup" = var.security_context.fs_group
      }
      
      "arbiter" = local.architecture == "replicaset" ? {
        "tolerations" = var.mongodb.node_selector != {} ? [
          for index in range(0, length(local.node_selector_keys)) : {
            key   = local.node_selector_keys[index]
            value = local.node_selector_values[index]
          }
        ] : []
      } : {}

      # As the parameter 'tls.mTLS.enabled' set to false doesn't seem to work (chart v15.1.4) this an
      # alternative to allow mTLS to not be mandatory
      "extraFlags" = "--tlsAllowConnectionsWithoutCertificates"

      "persistentVolumeClaimRetentionPolicy" = var.persistent_volume != null ? {
        "enabled"     = "true"
        "whenDeleted" = "Delete"
      } : {}
    })
  ]

  dynamic "set" {
    for_each = var.persistent_volume == null ? [1] : []
    content {
      name  = "persistence.enabled"
      value = false
    }
  }
  dynamic "set" {
    for_each = var.persistent_volume != null ? [1] : []
    content {
      name  = "persistence.storageClass"
      value = kubernetes_storage_class.mongodb[0].metadata[0].name
    }
  }
  dynamic "set" {
    for_each = var.persistent_volume != null ? [1] : []
    content {
      name  = "persistence.accessMode[0]"
      value = var.persistent_volume.access_mode[0]
    }
  }
  dynamic "set" {
    for_each = var.persistent_volume != null ? [1] : []
    content {
      name  = "persistence.size"
      value = var.persistent_volume.resources.requests.storage
    }
  }

  set_sensitive {
    name  = "auth.rootUser"
    value = random_string.mongodb_admin_user.result
  }
  set_sensitive {
    name  = "auth.rootPassword"
    value = random_password.mongodb_admin_password.result
  }
  set_sensitive {
    name  = "auth.usernames[0]"
    value = random_string.mongodb_application_user.result
  }
  set_sensitive {
    name  = "auth.passwords[0]"
    value = random_password.mongodb_application_password.result
  }
}
