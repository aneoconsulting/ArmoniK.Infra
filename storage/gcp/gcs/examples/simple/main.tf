# Bucket names are unique across all of GCP
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

module "simple_bucket" {
  source   = "../../../gcs"
  name     = "simple-gcs-${random_string.suffix.result}"
  location = "EU"
}
