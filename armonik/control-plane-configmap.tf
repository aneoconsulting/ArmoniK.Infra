# configmap with all the variables
module "control_plane_aggregation" {
  source = "../utils/aggregator"
  conf_list = flatten([
    {
      env = merge(
        {
          Submitter__DefaultPartition     = local.default_partition
          InitServices__InitDatabase      = !local.job_init,
          InitServices__InitObjectStorage = !local.job_init,
          InitServices__InitQueue         = !local.job_init,
          InitServices__StopAfterInit     = false,
        },
        !local.job_init && !local.job_partitions ? local.init_partitions_env : {},
        !local.job_init && !local.job_authentication ? local.init_authentication_users_env : {},
        !local.job_init && !local.job_authentication ? local.init_authentication_roles_env : {},
        !local.job_init && !local.job_authentication ? local.init_authentication_certs_env : {},
      )
    },
    module.log_aggregation,
    module.core_aggregation,
    var.configurations.control,
  ])

  materialize_configmap = {
    name      = "control-plane-configmap"
    namespace = var.namespace
  }
}
