# configmap with all the variables
module "control_aggregation" {
  source = "../utils/aggregator"
  conf_list = [{
    env = {
      Submitter__DefaultPartition = try(contains(local.partition_names, coalesce(local.default_partition)), false) ? local.default_partition : try(local.partition_names[0], "")
    }
    },
    {
      env = var.extra_conf.control
    }
  ]
  materialize_configmap = {
    name      = "control-plane-configmap"
    namespace = var.namespace
  }
}
