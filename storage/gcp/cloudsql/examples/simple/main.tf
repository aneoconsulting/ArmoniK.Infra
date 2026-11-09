module "simple_cloudsql" {
  source              = "../.."
  name                = "cloudsql-simple"
  network             = var.network
  psc_subnets         = var.psc_subnets
  deletion_protection = false
}
