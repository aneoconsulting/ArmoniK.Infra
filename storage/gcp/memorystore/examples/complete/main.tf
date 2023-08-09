locals {
  redis_configs = {
    "maxmemory-policy"        = "noeviction",
    "notify-keyspace-events"  = "Elg",
    "activedefrag"            = "yes",
    "lfu-decay-time"          = "1",
    "lfu-log-factor"          = "10",
    "maxmemory"               = "1gb",
    "stream-node-max-bytes"   = "4096",
    "stream-node-max-entries" = "100",
  }
  maintenance_policy = {
    day        = "MONDAY"
    start_time = {
      hours   = 12
      minutes = 0
      seconds = 0
      nanos   = 0
    }
  }
  persistence_config = {
    persistence_mode        = "DISABLED"
    rdb_snapshot_period     = "ONE_HOUR"
    rdb_snapshot_start_time = "2025-10-02T14:01:23Z"
  }
  date = <<-EOT
#!/bin/bash
set -e
DATE=$(date +%F-%H-%M-%S)
jq -n --arg date "$DATE" '{"date":$date}'
  EOT
}

resource "local_file" "date_sh" {
  filename = "${path.module}/generated/date.sh"
  content  = local.date
}

data "external" "static_timestamp" {
  program     = ["bash", "date.sh"]
  working_dir = "${path.module}/generated"
  depends_on  = [local_file.date_sh]
}

resource "null_resource" "timestamp" {
  triggers = {
    date = data.external.static_timestamp.result.date
  }
  lifecycle {
    ignore_changes = [triggers]
  }
}

module "complete_memorystore" {
  source                  = "../../../memorystore"
  name                    = "complete-redis-test"
  authorized_network      = "my-network-example"
  tier                    = "BASIC"
  memory_size_gb          = 2
  replica_count           = 3
  read_replicas_mode      = "READ_REPLICAS_ENABLED"
  alternative_location_id = "europe-west9-b"
  redis_version           = "latest"
  redis_configs           = local.redis_configs
  display_name            = "my-instance"
  reserved_ip_range       = "192.168.0.0/29"
  secondary_ip_range      = "10.0.0.0/29"
  connect_mode            = "DIRECT_PEERING"
  auth_enabled            = false
  transit_encryption_mode = "SERVER_AUTHENTICATION"
  maintenance_policy      = local.maintenance_policy
  customer_managed_key    = "my-encryption-key"
  persistence_config      = local.persistence_config
  labels = {
    env             = "test"
    app             = "complete"
    module          = "GCP Memorystore"
    "create_by"     = "me"
    "creation_date" = null_resource.timestamp.triggers["date"]
  }
}
