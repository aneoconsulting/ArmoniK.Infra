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

  labels = {
    "my-test-label-1" = "my-label",
    "my-test-label-2" = "my-label-2",
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
}

module "complex_memorystore" {
  source                  = "../../../memorystore"
  name                    = "redis-test"
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
  labels                  = local.labels
  auth_enabled            = false
  transit_encryption_mode = "SERVER_AUTHENTICATION"
  maintenance_policy      = local.maintenance_policy
  customer_managed_key    = "my-encryption-key"
  persistence_config      = local.persistence_config
}
