locals {
  # Service rendered by the chart in all-in-one mode, fullnameOverride being var.name
  host         = "${var.name}-all-in-one.${var.namespace}"
  port         = 8333 # S3 API
  console_port = 8888 # filer web UI
  url          = "http://${local.host}:${local.port}"

  # The Core S3 adapter settings
  must_force_path_style = true # http://host:port/bucket, no per-bucket DNS name in cluster
  use_chunk_encoding    = true
  use_checksum          = true

  resources = { for key, value in var.resources : key => value if value != null }

  persistence = { for key, value in {
    type         = var.persistence.type
    size         = var.persistence.size
    storageClass = var.persistence.storage_class
  } : key => value if value != null }

  tolerations = [
    for key, value in var.node_selector : {
      key      = key
      operator = "Equal"
      value    = value
      effect   = "NoSchedule"
    }
  ]
}
