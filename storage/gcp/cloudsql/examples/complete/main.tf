# A deleted instance keeps its name reserved for up to a week
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

module "complete_cloudsql" {
  source            = "../.."
  name              = "cloudsql-complete-${random_string.suffix.result}"
  region            = var.region
  network           = var.network
  psc_subnets       = var.psc_subnets
  database_version  = "POSTGRES_18"
  edition           = "ENTERPRISE"
  tier              = "db-custom-4-16384"
  availability_type = "REGIONAL"
  disk = {
    size       = 50
    autoresize = true
  }
  database_flags = {
    max_connections            = "1000"
    log_min_duration_statement = "1000"
  }
  database = "armonik"
  user     = "armonik"
  backup = {
    point_in_time_recovery = true
    start_time             = "02:00"
    retained_backups       = 14
  }
  maintenance_window = {
    day  = 7
    hour = 3
  }
  deletion_protection = false
  labels = {
    env = "test"
  }
}
