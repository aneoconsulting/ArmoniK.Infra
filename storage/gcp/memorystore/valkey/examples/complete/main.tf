data "google_client_openid_userinfo" "current" {}

locals {
  labels = {
    env    = "test"
    app    = "complete"
    module = "memorystore-valkey"
    # Label values only allow lowercase letters, digits, "_" and "-"
    created_by = replace(lower(split("@", data.google_client_openid_userinfo.current.email)[0]), "/[^a-z0-9_-]/", "_")
  }
}

module "vpc" {
  source = "../../../../../../networking/gcp/vpc"
  name   = "valkey-complete"
  gke_subnet = {
    name                = "valkey-complete-gke"
    nodes_cidr_block    = "10.43.0.0/16"
    pods_cidr_block     = "172.16.0.0/16"
    services_cidr_block = "172.17.17.0/24"
    region              = var.region
  }
  # The endpoints get an address of this range, known before the instance exists, to allow in NetworkPolicies
  subnets = {
    "valkey-complete-psc" = {
      cidr_block = "10.44.0.0/28"
      region     = var.region
    }
  }
  service_connection_policies = {
    memorystore = {
      service_class = "gcp-memorystore"
      subnets       = ["valkey-complete-psc"]
    }
  }
}

# Encrypts the data at rest
module "kms" {
  source        = "../../../../../../security/gcp/kms"
  key_ring_name = "valkey-complete"
  location      = var.region
  crypto_keys   = { "valkey" = {} }
  labels        = local.labels
}

module "complete_valkey" {
  source         = "../../../valkey"
  name           = "valkey-complete"
  network        = module.vpc.id
  node_type      = "STANDARD_SMALL"
  replica_count  = 1
  engine_version = "VALKEY_8_0"
  # Core sets a TTL on every object (Redis__TtlTimeSpan): evict the least recently used ones when memory runs out
  engine_configs = {
    "maxmemory-policy" = "volatile-lru"
  }
  zone_distribution = {
    mode = "MULTI_ZONE"
  }
  persistence = {
    mode                = "RDB"
    rdb_snapshot_period = "ONE_HOUR"
  }
  maintenance_window = {
    day   = "SATURDAY"
    hours = 2
  }
  kms_key             = { id = module.kms.crypto_key_ids["valkey"] }
  deletion_protection = false
  labels              = local.labels
  # The endpoints are only created where a service connection policy exists
  depends_on = [module.vpc]
}
