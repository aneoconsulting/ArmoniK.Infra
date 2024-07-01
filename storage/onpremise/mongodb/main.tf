locals {
  # To ensure image pull secrets are passed as an array/list
  image_pull_secrets = try(tolist(var.mongodb.image_pull_secrets), [tostring(var.mongodb.image_pull_secrets)])
}

resource "null_resource" "mongodb" {
  triggers = {
    "namespace" = var.namespace
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "kubectl delete pvc -n ${self.triggers.namespace} --all"
    on_failure = continue
  }
}

resource "helm_release" "mongodb" {
  name       = var.name
  namespace  = null_resource.mongodb.triggers.namespace
  chart      = var.mongodb.helm_chart_name
  repository = var.mongodb.helm_chart_repository
  version    = var.mongodb.helm_chart_version
  timeout    = 300 #var.timeout * var.mongodb.replicas_number

  values = [
    yamlencode({
      "commonLabels" = var.labels
      "shards"       = 2

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
        "podLabels"                 = var.labels
        "mongodbSystemLogVerbosity" = 5
      }

      "volumePermissions" = {
        "resourcesPrest" = "micro"
      }

      "service" = {
        #"name" = "mongodb-sharded-mysvc"
      }

      "networkPolicy" = {
        "enabled" = true
      }

      "configsvr" = {
        "replicaCount" = 1
        #   "mongodbExtraFlags" = var.mtls ? [""] : ["--tlsAllowConnectionsWithoutCertificates"]
          "nodeSelector"      = var.mongodb.node_selector

          "tolerations" = var.mongodb.node_selector != {} ? [
            for index in range(0, length(local.node_selector_keys)) : {
              key   = local.node_selector_keys[index]
              value = local.node_selector_values[index]
            }
          ] : []
      }

      "mongos" = {
        "replicaCount" = 1
        #   "mongodbExtraFlags" = var.mtls ? [""] : ["--tlsAllowConnectionsWithoutCertificates"]
          "nodeSelector"      = var.mongodb.node_selector

          "tolerations" = var.mongodb.node_selector != {} ? [
            for index in range(0, length(local.node_selector_keys)) : {
              key   = local.node_selector_keys[index]
              value = local.node_selector_values[index]
            }
          ] : []

          "podLabels"      = var.labels
      }

      "shardsvr" = {
        "dataNode" = {
        "replicaCount"      = 1
        #     "mongodbExtraFlags" = var.mtls ? [""] : ["--tlsAllowConnectionsWithoutCertificates"]
            "nodeSelector"      = var.mongodb.node_selector

            "tolerations" = var.mongodb.node_selector != {} ? [
              for index in range(0, length(local.node_selector_keys)) : {
                key   = local.node_selector_keys[index]
                value = local.node_selector_values[index]
              }
            ] : []

            "podLabels" = var.labels
        }

        # "persistence" = {
        #   "resourcePolicy" = "delete"
        # }

        #   "arbiter" = {
        #     "replicaCount" = 1
        #     "nodeSelector" = var.mongodb.node_selector

        #     "tolerations" = var.mongodb.node_selector != {} ? [
        #       for index in range(0, length(local.node_selector_keys)) : {
        #         key   = local.node_selector_keys[index]
        #         value = local.node_selector_values[index]
        #       }
        #     ] : []
        #   }

        #   "metrics" = {
        #   }
      }

    })
  ]

  # set_sensitive {
  #   name  = "auth.rootUser"
  #   value = random_string.mongodb_admin_user.result
  # }
  # set_sensitive {
  #   name  = "auth.rootPassword"
  #   value = random_password.mongodb_admin_password.result
  # }
}