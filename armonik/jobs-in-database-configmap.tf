locals {
  include_mount_configmap = local.authentication_require_authentication
  mount_configmap = local.include_mount_configmap ? {
    "mongodb-script" = {
      configmap = kubernetes_config_map.authmongo[0].metadata[0].name
      path      = "/mongodb/script"
    }
  } : {}
}

# configmap with all the variables
module "job_aggregation" {
  source = "../utils/aggregator"
  conf_list = flatten([{
    mount_configmap = local.mount_configmap
  }, var.configurations.core, var.configurations.jobs])
  materialize_configmap = {
    name      = "jobs-configmap"
    namespace = var.namespace
  }
}
