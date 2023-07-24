module "simple_memorystore" {
  source           = "../../../memorystore"
  region           = "europe-west9"
  project_id       = "armonik-gcp-13469"
  name             = "redis-test"
  credentials_file = "~/.config/gcloud/application_default_credentials.json"
}
