# configmap with all the variables
module "compute_all_aggregation" {
  source    = "../utils/aggregator"
  conf_list = flatten([module.log_aggregation, var.configurations.compute])
  materialize_configmap = {
    name      = "compute-plane-configmap"
    namespace = var.namespace
  }
}

module "polling_all_aggregation" {
  source = "../utils/aggregator"
  conf_list = flatten([{
    env = {
      ComputePlane__MessageBatchSize = "1"
      InitWorker__WorkerCheckRetries = "10"       # TODO: make it a variable
      InitWorker__WorkerCheckDelay   = "00:00:10" # TODO: make it a variable
      Amqp__LinkCredit               = "2"
      Pollster__GraceDelay           = "00:00:15"
    }
  }, module.core_aggregation, module.compute_aggregation, var.configurations.polling])
  materialize_configmap = {
    name      = "polling-configmap"
    namespace = var.namespace
  }
}

module "worker_all_aggregation" {
  source = "../utils/aggregator"
  conf_list = flatten([{
    env = {
      target_data_path = "/data"
      FileStorageType  = local.check_file_storage_type
    }
    }, {
    env = local.file_storage_endpoints
  }, module.compute_aggregation, var.configurations.worker])
  materialize_configmap = {
    name      = "worker-configmap"
    namespace = var.namespace
  }
}
