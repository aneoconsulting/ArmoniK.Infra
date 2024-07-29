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
      "shards"       = var.mongodb.shards_number

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
        "initScriptsCM"             = kubernetes_config_map.database_init_script.metadata[0].name
        "extraEnvVarsCM"            = kubernetes_config_map.mongodb_extra_env_vars.metadata[0].name
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
        "resourcesPrest" = "micro"
      }

      "service" = {
        #"name" = "mongodb-sharded-mysvc"
        "ports.mongodb" = floor(var.mongodb.service_port)
      }

      "networkPolicy" = {
        "enabled" = true
      }

      "configsvr" = {
        "replicaCount"      = var.mongodb.configsvr_replicas_number
        "mongodbExtraFlags" = local.mongodb_extra_flags
        "nodeSelector"      = var.mongodb.node_selector

        "tolerations" = var.mongodb.node_selector != {} ? [
          for key, value in var.mongodb.node_selector : {
            "key"   = key
            "value" = value
          }
        ] : []

        podLabels = var.labels
      }

      "mongos" = {
        "replicaCount"      = var.mongodb.mongos_replicas_number
        "mongodbExtraFlags" = local.mongodb_extra_flags
        "nodeSelector"      = var.mongodb.node_selector

        "tolerations" = var.mongodb.node_selector != {} ? [
          for key, value in var.mongodb.node_selector : {
            "key"   = key
            "value" = value
          }
        ] : []

        "podLabels" = var.labels
      }

      "shardsvr" = {
        "dataNode" = {
          "replicaCount"      = var.mongodb.replicas_number
          "mongodbExtraFlags" = local.mongodb_extra_flags
          "nodeSelector"      = var.mongodb.node_selector

          "tolerations" = var.mongodb.node_selector != {} ? [
            for key, value in var.mongodb.node_selector : {
              "key"   = key
              "value" = value
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
}
