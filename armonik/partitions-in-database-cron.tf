resource "kubernetes_cron_job_v1" "partitions_in_database" {
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
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    starting_deadline_seconds     = 20
    successful_jobs_history_limit = 0
    suspend                       = false
    schedule                      = "* * * * *"
    job_template {
      metadata {
        name = "partitions-in-database"
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
              command           = ["/bin/bash", "-c", local.script_cron]

              #env from config
              dynamic "env" {
                for_each = module.job_aggregation.env
                content {
                  name  = env.key
                  value = env.value
                }
              }

              #env from secret
              dynamic "env" {
                for_each = module.job_aggregation.env_from_secret
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
                for_each = module.job_aggregation.env_configmap
                content {
                  config_map_ref {
                    name = env_from.value
                  }
                }
              }

              dynamic "env_from" {
                for_each = module.job_aggregation.env_secret
                content {
                  secret_ref {
                    name = env_from.value
                  }
                }
              }
              dynamic "env" {
                for_each = module.job_aggregation.env_from_configmap
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
              #mount from conf
              dynamic "volume_mount" {
                for_each = module.job_aggregation.mount_secret
                content {
                  mount_path = volume_mount.value.path
                  name       = volume_mount.value.secret
                  read_only  = true
                }
              }
              dynamic "volume_mount" {
                for_each = module.job_aggregation.mount_configmap
                content {
                  name       = volume_mount.value.configmap
                  mount_path = volume_mount.value.path
                  sub_path   = lookup(volume_mount.value, "subpath", null)
                  read_only  = true
                }
              }
            }
            #form conf
            dynamic "volume" {
              for_each = module.job_aggregation.mount_secret
              content {
                name = volume.value.secret
                secret {
                  secret_name  = volume.value.secret
                  default_mode = volume.value.mode
                }
              }
            }

            dynamic "volume" {
              for_each = module.job_aggregation.mount_configmap
              content {
                name = volume.value.configmap
                config_map {
                  name         = volume.value.configmap
                  default_mode = volume.value.mode
                  dynamic "items" {
                    for_each = try(coalesce(volume.value.items), {})
                    content {
                      key  = items.key
                      path = items.value.field
                      mode = items.value.mode
                    }
                  }
                }
              }
            }
          }
        }
        backoff_limit = 5
      }
    }
  }
}

locals {
  script_cron = <<EOF
  if [ -z "$MongoDB__ConnectionString" ]; then
    MongoDB__ConnectionString="mongodb+srv://$MongoDB__User:$MongoDB__Password@$MongoDB__Host/$MongoDB__DatabaseName" # Note: This will only work if the 'MongoDB__User' is created in the db 'MongoDB__DatabaseName'
  fi
  export nbElements=$(mongosh --tlsCAFile "$MongoDB__CAFile" --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls "$MongoDB__ConnectionString" --eval 'db.PartitionData.countDocuments()' --quiet)
  if [[ $nbElements != ${length(local.partition_names)} ]]; then
    mongosh --tlsCAFile "$MongoDB__CAFile" --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls "$MongoDB__ConnectionString" --eval 'db.PartitionData.insertMany(${jsonencode(local.partitions_data)})'
  fi
  EOF
}
