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
    }
  }
}

locals {
  script_cron = <<EOF
#!/bin/bash
export nbElements=$(mongosh --tlsCAFile $MongoDB__CAFile --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls --username $MongoDB__User --password $MongoDB__Password mongodb://$MongoDB__Host:$MongoDB__Port/database?directConnection=false --eval 'db.PartitionData.countDocuments()' --quiet)
if [[ $nbElements != ${length(local.partition_names)} ]]; then
  mongosh --tlsCAFile $MongoDB__CAFile --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls --username $MongoDB__User --password $MongoDB__Password mongodb://$MongoDB__Host:$MongoDB__Port/database?directConnection=false --eval 'db.PartitionData.insertMany(${jsonencode(local.partitions_data)})'
fi
EOF
}
