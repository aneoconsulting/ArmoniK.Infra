module "simple_mongodb_instance" {
  source    = "../../"
  namespace = var.namespace
  mongodb = {
    tag = "6.0.7"
  }
  mongodb_helm_chart = {
    version = "15.1.4"
  }
}
