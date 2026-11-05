locals {
  # Service rendered by the chart in all-in-one mode, fullnameOverride being var.name
  host         = "${var.name}-all-in-one.${var.namespace}"
  port         = 8333 # S3 API
  console_port = 8888 # filer web UI
  url          = "http://${local.host}:${local.port}"

  # The Core S3 adapter settings, same as for MinIO
  must_force_path_style = true # http://host:port/bucket, no per-bucket DNS name in cluster
  use_chunk_encoding    = true
  use_checksum          = true

  resources = { for key, value in var.resources : key => value if value != null }

  persistence = { for key, value in {
    type         = var.seaweedfs.persistence.type
    size         = var.seaweedfs.persistence.size
    storageClass = var.seaweedfs.persistence.storage_class
  } : key => value if value != null }

  # Same toleration convention as the other onpremise storage modules
  tolerations = [
    for key, value in var.seaweedfs.node_selector : {
      key      = key
      operator = "Equal"
      value    = value
      effect   = "NoSchedule"
    }
  ]
}
