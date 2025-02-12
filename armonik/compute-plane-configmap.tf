# configmap with all the variables
module "compute_aggregation" {
  source   = "../utils/aggregator"
  for_each = var.compute_plane
  conf_list = flatten([
    {
      env = {
        ComputePlane__WorkerChannel__Address    = each.value.socket_type == "tcp" ? "http://localhost:10667" : "/cache/armonik_worker.sock"
        ComputePlane__WorkerChannel__SocketType = each.value.socket_type
        ComputePlane__AgentChannel__Address     = each.value.socket_type == "tcp" ? "http://localhost:10666" : "/cache/armonik_agent.sock"
        ComputePlane__AgentChannel__SocketType  = each.value.socket_type
      }
    },
  module.log_aggregation, var.configurations.compute])
  materialize_configmap = {
    name      = "compute-plane-${each.key}-configmap"
    namespace = var.namespace
  }
}

module "polling_all_aggregation" {
  source   = "../utils/aggregator"
  for_each = var.compute_plane
  conf_list = flatten([{
    env = {
      ComputePlane__MessageBatchSize = "1"
      InitWorker__WorkerCheckRetries = "10"       # TODO: make it a variable
      InitWorker__WorkerCheckDelay   = "00:00:10" # TODO: make it a variable
      Amqp__LinkCredit               = "2"
      Pollster__GraceDelay           = "00:00:15"
    }
  }, module.core_aggregation, module.compute_aggregation[each.key], var.configurations.polling])
  materialize_configmap = {
    name      = "polling-${each.key}-configmap"
    namespace = var.namespace
  }
}

module "worker_all_aggregation" {
  source   = "../utils/aggregator"
  for_each = var.compute_plane
  conf_list = flatten([{
    env = {
      target_data_path = "/data"
      FileStorageType  = local.check_file_storage_type
    }
    }, {
    env = local.file_storage_endpoints
  }, module.compute_aggregation[each.key], var.configurations.worker])
  materialize_configmap = {
    name      = "worker-${each.key}-configmap"
    namespace = var.namespace
  }
}
