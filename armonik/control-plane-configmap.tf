# configmap with all the variables
# resource "kubernetes_config_map" "control_plane_config" {
#   metadata {
#     name      = "control-plane-configmap"
#     namespace = var.namespace
#   }
#   data = merge(var.extra_conf.control, {
#     Submitter__DefaultPartition = (local.default_partition == null || local.default_partition == "" || !contains(local.partition_names, local.default_partition) ? (length(local.partition_names) > 0 ? local.partition_names[0] : "") : local.default_partition)
#   })
# }

module "control_aggregation" {
  source = "../utils/aggregator"
  conf_list = [{
    env = merge({
      Submitter__DefaultPartition = (local.default_partition == null || local.default_partition == "" || !contains(local.partition_names, local.default_partition) ? (length(local.partition_names) > 0 ? local.partition_names[0] : "") : local.default_partition)
    }, var.extra_conf.control)
  }]
  materialize_configmap = {
    name      = "control-plane-configmap"
    namespace = var.namespace
  }
}
