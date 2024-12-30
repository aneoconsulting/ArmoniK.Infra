locals {
  # Supported message queues by ArmoniK
  supported_queues = toset(["Amqp__PartitionId", "PubSub__PartitionId", "SQS__PartitionId"])

  # list of partitions
  partition_names   = keys(try(var.compute_plane, {}))
  default_partition = try(contains(local.partition_names, coalesce(var.control_plane.default_partition)), false) ? var.control_plane.default_partition : try(local.partition_names[0], "")

  # Node selector for control plane
  control_plane_node_selector        = try(var.control_plane.node_selector, {})
  control_plane_node_selector_keys   = keys(local.control_plane_node_selector)
  control_plane_node_selector_values = values(local.control_plane_node_selector)

  # Node selector for ingress
  ingress_node_selector        = try(var.ingress.node_selector, {})
  ingress_node_selector_keys   = keys(local.ingress_node_selector)
  ingress_node_selector_values = values(local.ingress_node_selector)

  # Node selector for admin GUI
  admin_gui_node_selector        = try(var.admin_gui.node_selector, {})
  admin_gui_node_selector_keys   = keys(local.admin_gui_node_selector)
  admin_gui_node_selector_values = values(local.admin_gui_node_selector)

  # Node selector for compute plane
  compute_plane_node_selector        = { for partition, compute_plane in var.compute_plane : partition => try(compute_plane.node_selector, {}) }
  compute_plane_node_selector_keys   = { for partition in local.partition_names : partition => keys(local.compute_plane_node_selector[partition]) }
  compute_plane_node_selector_values = { for partition in local.partition_names : partition => values(local.compute_plane_node_selector[partition]) }

  # Node selector for pod to insert partitions IDs in database
  job_partitions_in_database_node_selector        = try(var.job_partitions_in_database.node_selector, {})
  job_partitions_in_database_node_selector_keys   = keys(local.job_partitions_in_database_node_selector)
  job_partitions_in_database_node_selector_values = values(local.job_partitions_in_database_node_selector)

  # Node selector for pod to insert authentication data in database
  job_authentication_in_database_node_selector        = try(var.authentication.node_selector, {})
  job_authentication_in_database_node_selector_keys   = keys(local.job_authentication_in_database_node_selector)
  job_authentication_in_database_node_selector_values = values(local.job_authentication_in_database_node_selector)

  # Authentication
  authentication_require_authentication = try(var.authentication.require_authentication, false)
  authentication_require_authorization  = try(var.authentication.require_authorization, false)

  # Annotations
  control_plane_annotations = try(var.control_plane.annotations, {})
  compute_plane_annotations = { for partition in local.partition_names : partition => try(var.compute_plane[partition].annotations, {}) }
  ingress_annotations       = try(var.ingress.annotations, {})

  # Shared storage
  file_storage_type       = var.shared_storage_settings != null ? lower(var.shared_storage_settings.file_storage_type) : "FS"
  check_file_storage_type = local.file_storage_type == "s3" ? "S3" : "FS"
  file_storage_endpoints = local.check_file_storage_type == "S3" ? {
    S3Storage__ServiceURL         = var.shared_storage_settings.service_url
    S3Storage__AccessKeyId        = var.shared_storage_settings.access_key_id
    S3Storage__SecretAccessKey    = var.shared_storage_settings.secret_access_key
    S3Storage__BucketName         = var.shared_storage_settings.name
    S3Storage__MustForcePathStyle = var.shared_storage_settings.must_force_path_style
  } : {}

  # Fluent-bit volumes
  # Please don't change below read-only permissions
  fluent_bit_volumes = {
    fluentbitstate = {
      mount_path = "/var/fluent-bit/state"
      read_only  = false
      type       = "host_path"
    }
    varlog = {
      mount_path = "/var/log"
      read_only  = true
      type       = "host_path"
    }
    varlibdockercontainers = {
      mount_path = "/var/lib/docker/containers"
      read_only  = true
      type       = "host_path"
    }
    runlogjournal = {
      mount_path = "/run/log/journal"
      read_only  = true
      type       = "host_path"
    }
    dmesg = {
      mount_path = "/var/log/dmesg"
      read_only  = true
      type       = "host_path"
    }
    fluentbitconfig = {
      mount_path = "/fluent-bit/etc/"
      read_only  = false
      type       = "config_map"
    }
  }
  # Fluent-bit volumes windows
  fluent_bit_windows_volumes = !var.fluent_bit.windows_is_daemonset ? local.volumes_info : {}
  volumes_info = {
    windowsfluentbitstate = {
      mount_path = "C:\\var\\fluent-bit\\state"
      read_only  = false
      type       = "host_path"
    }
    windowsvarlog = {
      mount_path = "C:\\var\\log"
      read_only  = true
      type       = "host_path"
    }
    windowsvarlibdockercontainers = {
      mount_path = "C:\\ProgramData\\docker\\containers"
      read_only  = true
      type       = "host_path"
    }
    windowsrunlogjournal = {
      mount_path = "C:\\run\\log\\journal"
      read_only  = true
      type       = "host_path"
    }
    windowsdmesg = {
      mount_path = "C:\\var\\log\\dmesg"
      read_only  = true
      type       = "host_path"
    }
    windowsfluentbitconfig = {
      mount_path = "C:\\fluent-bit\\etc"
      read_only  = false
      type       = "config_map"
      content    = var.fluent_bit.windows_configmaps.config
    }
    windowsfluentbitentry = {
      mount_path = "C:\\fluent-bit\\entrypoint.ps1"
      sub_path   = "entrypoint.ps1"
      read_only  = false
      type       = "config_map"
      content    = var.fluent_bit.windows_configmaps.entry
    }
  }

  # Partitions data
  partitions_data = [
    for key, value in var.compute_plane : {
      _id                  = key
      ParentPartitionIds   = value.partition_data.parent_partition_ids
      PodReserved          = value.partition_data.reserved_pods
      PodMax               = value.partition_data.max_pods
      PreemptionPercentage = value.partition_data.preemption_percentage
      Priority             = value.partition_data.priority
      PodConfiguration     = value.partition_data.pod_configuration
    }
  ]

  # HPA scalers
  # Compute plane
  hpa_compute_plane_triggers = {
    for partition, value in var.compute_plane : partition => {
      triggers = [
        for trigger in try(value.hpa.triggers, []) :
        (lower(try(trigger.type, "")) == "prometheus" ? {
          type = "prometheus"
          metadata = {
            serverAddress = var.prometheus.url
            metricName    = "armonik_${partition}_tasks_queued"
            threshold     = tostring(try(trigger.threshold, "2"))
            namespace     = var.metrics.namespace
            query         = "armonik_${partition}_tasks_queued{job=\"${var.metrics.name}\"}"
          }
          } :
          (lower(try(trigger.type, "")) == "cpu" || lower(try(trigger.type, "")) == "memory" ? {
            type       = lower(trigger.type)
            metricType = try(trigger.metric_type, "Utilization")
            metadata = {
              value = try(trigger.value, "80")
            }
        } : object({})))
      ]
    }
  }

  compute_plane_triggers = {
    for partition in local.partition_names : partition => {
      triggers = [for trigger in local.hpa_compute_plane_triggers[partition].triggers : trigger if trigger != {}]
    }
  }

  # Control plane
  hpa_control_plane_triggers = {
    triggers = [
      for trigger in try(var.control_plane.hpa.triggers, []) :
      (lower(try(trigger.type, "")) == "cpu" || lower(try(trigger.type, "")) == "memory" ? {
        type       = lower(trigger.type)
        metricType = try(trigger.metric_type, "Utilization")
        metadata = {
          value = try(trigger.value, "80")
        }
      } : object({}))
    ]
  }

  control_plane_triggers = {
    triggers = [for trigger in local.hpa_control_plane_triggers.triggers : trigger if trigger != {}]
  }

  #metrics
  metrics_exporter = {
    node_selector_keys   = keys(var.metrics_exporter.node_selector)
    node_selector_values = values(var.metrics_exporter.node_selector)
  }
}
