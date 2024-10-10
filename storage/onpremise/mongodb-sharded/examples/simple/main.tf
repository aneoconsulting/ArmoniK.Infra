module "sharded_mongodb" {
  source    = "../../"
  namespace = var.namespace
  name      = "mongodb-sharded"
  timeout   = 300

  mongodb = {
    helm_chart_version = "8.3.8"
    tag                = "7.0.14-debian-12-r0"
  }
}
