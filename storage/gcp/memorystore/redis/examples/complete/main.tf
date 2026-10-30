data "google_client_openid_userinfo" "current" {}

locals {
  redis_configs = {
    "activedefrag"             = "no"
    "lazyfree-lazy-eviction"   = "no"
    "lazyfree-lazy-expire"     = "no"
    "lazyfree-lazy-user-del"   = "no"
    "lazyfree-lazy-user-flush" = "no"
    "maxmemory-clients"        = "0%"
    "maxmemory-gb"             = "2.0"
    "maxmemory-policy"         = "volatile-lru"
    "notify-keyspace-events"   = "AKE"
    "lfu-decay-time"           = "1"
    "lfu-log-factor"           = "10"
    "stream-node-max-bytes"    = "4096"
    "stream-node-max-entries"  = "100"
    "timeout"                  = "0"
  }
  maintenance_policy = {
    day = "MONDAY"
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
  labels = {
    env             = "test"
    app             = "complete"
    module          = "GCP Memorystore for Redis"
    "create_by"     = split("@", data.google_client_openid_userinfo.current.email)[0]
    "creation_date" = null_resource.timestamp.triggers["date"]
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

data "google_compute_network" "vpc" {
  name = "default-${var.region}"
}

data "google_compute_subnetwork" "subnet" {
  name   = "default-${var.region}"
  region = var.region
}

data "google_compute_zones" "available" {}

module "complete_memorystore_for_redis" {
  source             = "../../../redis"
  name               = "complete-redis-test"
  memory_size_gb     = 5
  auth_enabled       = true
  authorized_network = data.google_compute_network.vpc.name
  connect_mode       = "DIRECT_PEERING"
  display_name       = "complete-redis-test"
  labels             = local.labels
  locations = length(data.google_compute_zones.available.names) >= 2 ? [
    data.google_compute_zones.available.names[0],
    data.google_compute_zones.available.names[1]
  ] : [data.google_compute_zones.available.names[0]]
  redis_configs           = local.redis_configs
  persistence_config      = local.persistence_config
  maintenance_policy      = local.maintenance_policy
  redis_version           = "REDIS_7_0"
  reserved_ip_range       = data.google_compute_subnetwork.subnet.ip_cidr_range
  tier                    = "STANDARD_HA"
  transit_encryption_mode = "SERVER_AUTHENTICATION"
  replica_count           = 3
  read_replicas_mode      = "READ_REPLICAS_ENABLED"
  secondary_ip_range      = "10.0.0.0/29"
  customer_managed_key    = null
  namespace               = "default"
  path                    = "/redis"
}
