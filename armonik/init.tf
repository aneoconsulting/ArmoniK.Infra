locals {
  init_partitions = [
    for key, value in var.compute_plane :
    {
      PartitionId          = key
      ParentPartitionIds   = value.partition_data.parent_partition_ids
      PodReserved          = value.partition_data.reserved_pods
      PodMax               = value.partition_data.max_pods
      PreemptionPercentage = value.partition_data.preemption_percentage
      Priority             = value.partition_data.priority
      PodConfiguration     = value.partition_data.pod_configuration
    }
  ]
  init_authentication_provided = can(coalesce(var.authentication.authentication_datafile)) ? jsondecode(file(var.authentication.authentication_datafile)) : null
  init_authentication_users = local.init_authentication_provided == null ? [
    for name, cert in data.tls_certificate.certificate_data : {
      Username = name,
      Roles    = [name]
    }
  ] : local.init_authentication_provided.users_list
  init_authentication_roles = local.init_authentication_provided == null ? [
    for name, cert in data.tls_certificate.certificate_data : {
      RoleName    = name,
      Permissions = local.ingress_generated_cert.permissions[name]
    }
  ] : local.init_authentication_provided.users_list

  init_authentication_certs = local.init_authentication_provided == null ? [
    for name, cert in data.tls_certificate.certificate_data : {
      Fingerprint = cert.certificates[length(cert.certificates) - 1].sha1_fingerprint,
      Cn          = tls_cert_request.ingress_client_cert_request[name].subject[0].common_name,
      Username    = name
    }
  ] : local.init_authentication_provided.certificates_list


  init_partitions_env = { for i, partition in local.init_partitions :
    "InitServices__Partitioning__Partitions__${i}" => jsonencode(partition)
  }
  init_authentication_users_env = { for i, user in local.init_authentication_users :
    "InitServices__Authentication__Users__${i}" => jsonencode(merge(user, { Name = user.Username }))
  }
  init_authentication_roles_env = { for i, role in local.init_authentication_roles :
    "InitServices__Authentication__Roles__${i}" => jsonencode(merge(role, { Name = role.RoleName }))
  }
  init_authentication_certs_env = { for i, cert in local.init_authentication_certs :
    "InitServices__Authentication__UserCertificates__${i}" => jsonencode(merge(cert, { User = cert.Username }))
  }
}

resource "kubernetes_job" "init" {
  count = local.job_init ? 1 : 0
  metadata {
    name      = var.init.name
    namespace = var.namespace
    labels = {
      app     = "armonik"
      service = "init"
    }
  }
  spec {
    template {
      metadata {
        name = "init"
        labels = {
          app     = "armonik"
          service = "init"
        }
        annotations = var.init.annotations
      }
      spec {
        node_selector = var.init.node_selector
        dynamic "toleration" {
          for_each = var.init.node_selector
          content {
            key      = toleration.key
            operator = "Equal"
            value    = toleration.value
            effect   = "NoSchedule"
          }
        }
        dynamic "image_pull_secrets" {
          for_each = (var.init.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.init.image_pull_secrets
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
        restart_policy       = "OnFailure" # Always, OnFailure, Never
        service_account_name = var.control_plane.service_account_name
        # Control plane container
        container {
          name              = var.init.name
          image             = var.init.tag != "" ? "${var.init.image}:${var.init.tag}" : var.init.image
          image_pull_policy = var.init.image_pull_policy
          #env from config
          dynamic "env" {
            for_each = module.job_aggregation.env
            content {
              name  = env.key
              value = env.value
            }
          }
          #env secret from config
          dynamic "env_from" {
            for_each = module.job_aggregation.env_secret
            content {
              secret_ref {
                name = env_from.value
              }
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
          dynamic "env_from" {
            for_each = module.job_aggregation.env_configmap
            content {
              config_map_ref {
                name = env_from.value
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
            env_from {
              config_map_ref {
                name = try(var.fluent_bit.windows_configmaps.envvars, "")
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
  wait_for_completion = true
  timeouts {
    create = "2m"
    update = "2m"
  }
}

resource "kubernetes_cron_job_v1" "init" {
  count = local.job_init ? 1 : 0
  metadata {
    name      = var.init.name
    namespace = var.namespace
    labels = {
      app     = "armonik"
      service = "init"
    }
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    starting_deadline_seconds     = 20
    successful_jobs_history_limit = 1
    suspend                       = false
    schedule                      = "* * * * *"
    job_template {
      metadata {
        name = "init"
        labels = {
          app     = "armonik"
          service = "init"
        }
        annotations = var.init.annotations
      }

      spec {
        template {
          metadata {
            name = "init"
            labels = {
              app     = "armonik"
              service = "init"
            }
            annotations = var.init.annotations
          }
          spec {
            node_selector = var.init.node_selector
            dynamic "toleration" {
              for_each = var.init.node_selector
              content {
                key      = toleration.key
                operator = "Equal"
                value    = toleration.value
                effect   = "NoSchedule"
              }
            }
            dynamic "image_pull_secrets" {
              for_each = (var.init.image_pull_secrets != "" ? [1] : [])
              content {
                name = var.init.image_pull_secrets
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
            restart_policy       = "OnFailure" # Always, OnFailure, Never
            service_account_name = var.control_plane.service_account_name
            # Control plane container
            container {
              name              = var.init.name
              image             = var.init.tag != "" ? "${var.init.image}:${var.init.tag}" : var.init.image
              image_pull_policy = var.init.image_pull_policy
              #env from config
              dynamic "env" {
                for_each = module.job_aggregation.env
                content {
                  name  = env.key
                  value = env.value
                }
              }
              #env secret from config
              dynamic "env_from" {
                for_each = module.job_aggregation.env_secret
                content {
                  secret_ref {
                    name = env_from.value
                  }
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
              dynamic "env_from" {
                for_each = module.job_aggregation.env_configmap
                content {
                  config_map_ref {
                    name = env_from.value
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
                env_from {
                  config_map_ref {
                    name = try(var.fluent_bit.windows_configmaps.envvars, "")
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
  }
}
