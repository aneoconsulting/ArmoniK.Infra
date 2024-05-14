module "simple_mongodb_instance" {
  source    = "../../"
  namespace = var.namespace
  mongodb = {
    tag = "6.0.7"
    helm_chart_version = "15.1.4"
  }
}
