locals {
    // Same as the default value defined for the variable "mongodb" in this module
    mongodb = {
        image               = "mongo"
        tag                 = "latest"
        node_selector       = {}
        image_pull_secrets  = ""
        replicas_number     = 1
    }
}

module "simple_mongodb_instance" {
    source = "../../"
    namespace = var.namespace
    mongodb = local.mongodb
}