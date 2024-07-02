module "simple_mongodb_instance" {
  source    = "../../"
  namespace = var.namespace
  mongodb = {
    tag                = "7.0.8-debian-12-r2"
    helm_chart_version = "15.1.4"
  }
}
