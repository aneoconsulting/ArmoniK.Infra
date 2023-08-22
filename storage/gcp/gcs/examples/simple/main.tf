module "simple_bucket" {
  source   = "../../../gcs"
  name     = "simple-gcs-bucket"
  location = "EU"
}
