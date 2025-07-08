module "simple_mongodb_instance" {
  source    = "../../"
  namespace = var.namespace
  mongodb = {
    tag                = "7.0.12-debian-12-r4"
    helm_chart_version = "15.6.12"
  }
  persistent_volume = {}
}
