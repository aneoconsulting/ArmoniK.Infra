locals {
  # list of partitions
  partition_names   = keys(try(var.compute_plane, {}))
  default_partition = try(var.control_plane.default_partition, "")

  # Node selector for control plane
  control_plane_node_selector        = try(var.control_plane.node_selector, {})
  control_plane_node_selector_keys   = keys(local.control_plane_node_selector)
  control_plane_node_selector_values = values(local.control_plane_node_selector)

  # Node selector for admin GUI
  admin_gui_node_selector        = try(var.admin_gui.node_selector, {})
  admin_gui_node_selector_keys   = keys(local.admin_gui_node_selector)
  admin_gui_node_selector_values = values(local.admin_gui_node_selector)

  # Node selector for compute plane
  compute_plane_node_selector        = {for partition, compute_plane in var.compute_plane : partition => try(compute_plane.node_selector, {})}
  compute_plane_node_selector_keys   = {for partition in local.partition_names : partition => keys(local.compute_plane_node_selector[partition])}
  compute_plane_node_selector_values = {for partition in local.partition_names : partition => values(local.compute_plane_node_selector[partition])}

  # Annotations
  control_plane_annotations = try(var.control_plane.annotations, {})
  compute_plane_annotations = {for partition in local.partition_names : partition => try(var.compute_plane[partition].annotations, {})}
  ingress_annotations       = try(var.ingress.annotations, {})

  # Shared storage
  service_url             = try(var.storage_endpoint_url.shared.service_url, "")
  kms_key_id              = try(var.storage_endpoint_url.shared.kms_key_id, "")
  name                    = try(var.storage_endpoint_url.shared.name, "")
  access_key_id           = try(var.storage_endpoint_url.shared.access_key_id, "")
  secret_access_key       = try(var.storage_endpoint_url.shared.secret_access_key, "")
  file_server_ip          = try(var.storage_endpoint_url.shared.file_server_ip, "")
  file_storage_type       = try(var.storage_endpoint_url.shared.file_storage_type, "")
  host_path               = try(var.storage_endpoint_url.shared.host_path, "")
  lower_file_storage_type = lower(local.file_storage_type)
  check_file_storage_type = (local.lower_file_storage_type == "s3" ? "S3" : "FS")

  # Storage secrets
  activemq_certificates_secret      = try(var.storage_endpoint_url.activemq.certificates.secret, "")
  mongodb_certificates_secret       = try(var.storage_endpoint_url.mongodb.certificates.secret, "")
  redis_certificates_secret         = try(var.storage_endpoint_url.redis.certificates.secret, "")
  activemq_credentials_secret       = try(var.storage_endpoint_url.activemq.credentials.secret, "")
  mongodb_credentials_secret        = try(var.storage_endpoint_url.mongodb.credentials.secret, "")
  redis_credentials_secret          = try(var.storage_endpoint_url.redis.credentials.secret, "")
  activemq_certificates_ca_filename = try(var.storage_endpoint_url.activemq.certificates.ca_filename, "")
  mongodb_certificates_ca_filename  = try(var.storage_endpoint_url.mongodb.certificates.ca_filename, "")
  redis_certificates_ca_filename    = try(var.storage_endpoint_url.redis.certificates.ca_filename, "")
  activemq_credentials_username_key = try(var.storage_endpoint_url.activemq.credentials.username_key, "")
  mongodb_credentials_username_key  = try(var.storage_endpoint_url.mongodb.credentials.username_key, "")
  redis_credentials_username_key    = try(var.storage_endpoint_url.redis.credentials.username_key, "")
  activemq_credentials_password_key = try(var.storage_endpoint_url.activemq.credentials.password_key, "")
  mongodb_credentials_password_key  = try(var.storage_endpoint_url.mongodb.credentials.password_key, "")
  redis_credentials_password_key    = try(var.storage_endpoint_url.redis.credentials.password_key, "")

  # Endpoint urls storage
  activemq_host     = try(var.storage_endpoint_url.activemq.host, "")
  activemq_port     = try(var.storage_endpoint_url.activemq.port, "")
  activemq_web_host = try(var.storage_endpoint_url.activemq.web_host, "")
  activemq_web_port = try(var.storage_endpoint_url.activemq.web_port, "")
  activemq_web_url  = try(var.storage_endpoint_url.activemq.web_url, "")
  mongodb_host      = try(var.storage_endpoint_url.mongodb.host, "")
  mongodb_port      = try(var.storage_endpoint_url.mongodb.port, "")
  redis_url         = try(var.storage_endpoint_url.redis.url, "")

  # Options of storage
  activemq_allow_host_mismatch = try(var.storage_endpoint_url.activemq.allow_host_mismatch, true)
  mongodb_allow_insecure_tls   = try(var.storage_endpoint_url.mongodb.allow_insecure_tls, true)
  redis_timeout                = try(var.storage_endpoint_url.redis.timeout, 3000)
  redis_ssl_host               = try(var.storage_endpoint_url.redis.ssl_host, "")

  # Fluent-bit
  fluent_bit_is_daemonset      = try(var.monitoring.fluent_bit.is_daemonset, false)
  fluent_bit_container_name    = try(var.monitoring.fluent_bit.container_name.fluent-bit, "fluent-bit")
  fluent_bit_image             = try(var.monitoring.fluent_bit.image, "fluent/fluent-bit")
  fluent_bit_tag               = try(var.monitoring.fluent_bit.tag, "1.7.2")
  fluent_bit_envvars_configmap = try(var.monitoring.fluent_bit.configmaps.envvars, "")
  fluent_bit_configmap         = try(var.monitoring.fluent_bit.configmaps.config, "")

  # Seq
  seq_host    = try(var.monitoring.seq.host, "")
  seq_port    = try(var.monitoring.seq.port, "")
  seq_url     = try(var.monitoring.seq.url, "")
  seq_web_url = try(var.monitoring.seq.web_url, "")

  # Grafana
  grafana_host = try(var.monitoring.grafana.host, "")
  grafana_port = try(var.monitoring.grafana.port, "")
  grafana_url  = try(var.monitoring.grafana.url, "")

  # Metrics exporter
  metrics_exporter_name      = try(var.monitoring.metrics_exporter.name, "")
  metrics_exporter_namespace = try(var.monitoring.metrics_exporter.namespace, "")

  # ingress ports
  ingress_ports = var.ingress != null ? distinct(compact([var.ingress.http_port, var.ingress.grpc_port])) : []

  # Polling delay to MongoDB
  mongodb_polling_min_delay = try(var.mongodb_polling_delay.min_polling_delay, "00:00:01")
  mongodb_polling_max_delay = try(var.mongodb_polling_delay.max_polling_delay, "00:05:00")

  # Credentials
  credentials = {
  for key, value in {
    Amqp__User        = local.activemq_credentials_secret != "" ? {
      key  = local.activemq_credentials_username_key
      name = local.activemq_credentials_secret
    } : { key = "", name = "" }
    Amqp__Password    = local.activemq_credentials_secret != "" ? {
      key  = local.activemq_credentials_password_key
      name = local.activemq_credentials_secret
    } : { key = "", name = "" }
    Redis__User       = local.redis_credentials_secret != "" ? {
      key  = local.redis_credentials_username_key
      name = local.redis_credentials_secret
    } : { key = "", name = "" }
    Redis__Password   = local.redis_credentials_secret != "" ? {
      key  = local.redis_credentials_password_key
      name = local.redis_credentials_secret
    } : { key = "", name = "" }
    MongoDB__User     = local.mongodb_credentials_secret != "" ? {
      key  = local.mongodb_credentials_username_key
      name = local.mongodb_credentials_secret
    } : { key = "", name = "" }
    MongoDB__Password = local.mongodb_credentials_secret != "" ? {
      key  = local.mongodb_credentials_password_key
      name = local.mongodb_credentials_secret
    } : { key = "", name = "" }
  } : key => value if !contains(values(value), "")
  }

  # Certificates
  certificates = {
  for key, value in {
    activemq = local.activemq_certificates_secret != "" ? {
      name        = "activemq-secret-volume"
      mount_path  = "/amqp"
      secret_name = local.activemq_certificates_secret
    } : { name = "", mount_path = "", secret_name = "" }
    redis    = local.redis_certificates_secret != "" ? {
      name        = "redis-secret-volume"
      mount_path  = "/redis"
      secret_name = local.redis_certificates_secret
    } : { name = "", mount_path = "", secret_name = "" }
    mongodb  = local.mongodb_certificates_secret != "" ? {
      name        = "mongodb-secret-volume"
      mount_path  = "/mongodb"
      secret_name = local.mongodb_certificates_secret
    } : { name = "", mount_path = "", secret_name = "" }
  } : key => value if !contains(values(value), "")
  }

  # HPA scalers
  # Compute plane
  hpa_compute_plane_triggers = {
  for partition in local.partition_names : partition => {
    triggers = [
    for trigger in try(var.compute_plane[partition].hpa.triggers, []) :
    (lower(try(trigger.type, "")) == "prometheus" ? {
      type     = "prometheus"
      metadata = {
        serverAddress = try(var.monitoring.prometheus.url, "")
        metricName    = try(trigger.metric_name, "armonik_tasks_queued")
        threshold     = try(trigger.threshold, "2")
        namespace     = local.metrics_exporter_namespace
        query         = "${try(trigger.metric_name, "armonik_tasks_queued")}{job=\"${local.metrics_exporter_name}\"}"
      }
    } :
    (lower(try(trigger.type, "")) == "cpu" || lower(try(trigger.type, "")) == "memory" ? {
      type       = lower(trigger.type)
      metricType = try(trigger.metric_type, "Utilization")
      metadata   = {
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
      metadata   = {
        value = try(trigger.value, "80")
      }
    } : lower(try(trigger.type, "")) == "prometheus" ? object({
      type     = "prometheus"
      metadata = {
        serverAddress = try(var.monitoring.prometheus.url, "")
        metricName    = try(trigger.metric_name, "armonik_tasks_queued")
        threshold     = try(trigger.threshold, "2")
        namespace     = local.metrics_exporter_namespace
        query         = "${try(trigger.metric_name, "armonik_tasks_queued")}{job=\"${local.metrics_exporter_name}\"}"
      }
    }) : object({}))
    ]
  }

  control_plane_triggers = {
    triggers = [for trigger in local.hpa_control_plane_triggers.triggers : trigger if trigger != {}]
  }
}
