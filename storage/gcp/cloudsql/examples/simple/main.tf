module "simple_cloudsql" {
  source              = "../.."
  name                = "cloudsql-simple"
  network             = var.network
  deletion_protection = false
}
