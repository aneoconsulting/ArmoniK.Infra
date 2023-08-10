locals {
  memcache_parameters = {
    # Modifiable configuration parameters
    "listen-backlog"          = "1024"
    "disable-flush-all"       = "false"
    "max-item-size"           = "1048576"
    "slab-min-size"           = "48"
    "slab-growth-factor"      = "1.25"
    "protocol"                = "auto"
    "disable-cas"             = "false"
    "disable-evictions"       = "false"
    "max-reqs-per-event"      = "20"
    "reserved-memory-percent" = "10.0"
    # Supported extended options
    "track_sizes"             = "false"
    "watcher_logbuf_size"     = "262144"
    "worker_logbuf_size"      = "65536"
    "lru_crawler"             = "true"
    "idle_timeout"            = "0"
    "lru_maintainer"          = "true"
    "maxconns_fast"           = "false"
    "hash_algorithm"          = "murmur3"
  }
  maintenance_policy = {
    day        = "MONDAY"
    duration   = "3.5s"
    start_time = {
      hours   = 12
      minutes = 0
      seconds = 0
      nanos   = 0
    }
  }
  labels = {
    env             = "test"
    app             = "complete"
    module          = "GCP Memorystore for Memcached Instance"
    "create_by"     = "me"
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

data "google_compute_zones" "available" {}

module "complete_memorystore_for_memcached_instance" {
  source              = "../../../memcache"
  name                = "complete-memcache-test"
  cpu_count           = 2
  memory_size_mb      = 512
  node_count          = 5
  authorized_network  = data.google_compute_network.vpc.name
  display_name        = "complete-memcache-test"
  labels              = local.labels
  maintenance_policy  = local.maintenance_policy
  memcache_version    = "MEMCACHE_1_5"
  memcache_parameters = local.memcache_parameters
  zones               = data.google_compute_zones.available.names
}
