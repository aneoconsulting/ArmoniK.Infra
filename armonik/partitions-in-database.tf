resource "kubernetes_job" "partitions_in_database" {
  metadata {
    name      = "partitions-in-database"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      service = "partitions-in-database"
      type    = "monitoring"
    }
  }
  spec {
    template {
      metadata {
        name = "partitions-in-database"
        labels = {
          app     = "armonik"
          service = "partitions-in-database"
          type    = "monitoring"
        }
      }
      spec {
        node_selector = local.job_partitions_in_database_node_selector
        dynamic "toleration" {
          for_each = (local.job_partitions_in_database_node_selector != {} ? [
            for index in range(0, length(local.job_partitions_in_database_node_selector_keys)) : {
              key   = local.job_partitions_in_database_node_selector_keys[index]
              value = local.job_partitions_in_database_node_selector_values[index]
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
          for_each = (var.job_partitions_in_database.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.job_partitions_in_database.image_pull_secrets
          }
        }
        restart_policy = "OnFailure" # Always, OnFailure, Never
        container {
          name              = var.job_partitions_in_database.name
          image             = var.job_partitions_in_database.tag != "" ? "${var.job_partitions_in_database.image}:${var.job_partitions_in_database.tag}" : var.job_partitions_in_database.image
          image_pull_policy = var.job_partitions_in_database.image_pull_policy
          command           = ["/bin/bash", "-c", local.script]
          # dynamic "env" {
          #   for_each = local.database_credentials
          #   content {
          #     name = env.key
          #     value_from {
          #       secret_key_ref {
          #         key      = env.value.key
          #         name     = env.value.name
          #         optional = false
          #       }
          #     }
          #   }
          # }
          #env from config
          dynamic "env" {
            for_each = module.partition_database_aggregation.env
            content {
              name  = env.key
              value = env.value
            }
          }

          #env from secret
          dynamic "env" {
            for_each = module.partition_database_aggregation.env_from_secret
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
            for_each = module.partition_database_aggregation.env_configmap
            content {
              config_map_ref {
                name = env_from.value
              }
            }
          }
          # env_from {
          #   config_map_ref {
          #     name = kubernetes_config_map.jobs_in_database_config.metadata[0].name
          #   }
          # }
          # volume_mount {
          #   name       = "mongodb-secret-volume"
          #   mount_path = "/mongodb"
          #   read_only  = true
          # }
          #mount from conf
          dynamic "volume_mount" {
            for_each = module.partition_database_aggregation.mount_secret
            content {
              mount_path = volume_mount.value.path
              name       = volume_mount.value.secret
              read_only  = true
            }
          }
        }
        # volume {
        #   name = "mongodb-secret-volume"
        #   secret {
        #     secret_name = local.secrets.mongodb.name
        #     optional    = false
        #   }
        # }
        #form conf
        dynamic "volume" {
          for_each = module.partition_database_aggregation.mount_secret
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
    backoff_limit = 5
  }
  wait_for_completion = true
  timeouts {
    create = "2m"
    update = "2m"
  }
}

locals {
  script = <<EOF
#!/bin/bash
# Drop
mongosh --tlsCAFile $MongoDB__CAFile --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls --username $MongoDB__User --password $MongoDB__Password mongodb://$MongoDB__Host:$MongoDB__Port/database --eval 'db.PartitionData.drop()'

# Insert
mongosh --tlsCAFile $MongoDB__CAFile --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls --username $MongoDB__User --password $MongoDB__Password mongodb://$MongoDB__Host:$MongoDB__Port/database --eval 'db.PartitionData.insertMany(${jsonencode(local.partitions_data)})'
EOF
}
