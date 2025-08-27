# configmap with all the variables
module "job_aggregation" {
  source = "../utils/aggregator"
  conf_list = flatten([
    {
      env = merge(
        local.job_init ? {
          InitServices__InitDatabase       = true,
          InitServices__InitObjectStorage  = true,
          InitServices__InitQueue          = true,
          InitServices__StopAfterInit      = true,
          Serilog__Properties__Application = "ArmoniK.Control.Init",
        } : {},
        local.job_init && !local.job_partitions ? local.init_partitions_env : {},
        local.job_init && !local.job_authentication ? local.init_authentication_users_env : {},
        local.job_init && !local.job_authentication ? local.init_authentication_roles_env : {},
        local.job_init && !local.job_authentication ? local.init_authentication_certs_env : {},
      )
      mount_configmap = local.job_authentication ? {
        "mongodb-script" = {
          configmap = kubernetes_config_map.authmongo[0].metadata[0].name
          path      = "/mongodb/script"
        }
      } : {}
    },
    module.core_aggregation,
    var.configurations.jobs,
  ])
  materialize_configmap = {
    name      = "jobs-configmap"
    namespace = var.namespace
  }
}
