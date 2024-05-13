module "simple_mongodb_instance" {
  source    = "../../"
  namespace = var.namespace
  mongodb = {
    image              = "mongo"
    tag                = "6.0.7"
    node_selector      = {}
    image_pull_secrets = ""
    replicas_number    = 1
  }
}
