# configmap with all the variables
module "control_plane_aggregation" {
  source = "../utils/aggregator"
  conf_list = flatten([{
    env = {
      Submitter__DefaultPartition = local.default_partition
    }
    }, module.log_aggregation, module.core_aggregation
  , var.configurations.control])

  materialize_configmap = {
    name      = "control-plane-configmap"
    namespace = var.namespace
  }
}
