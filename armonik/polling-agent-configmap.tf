# configmap with all the variables
module "polling_aggregation" {
  source = "../utils/aggregator"
  conf_list = [{
    env = {
      ComputePlane__MessageBatchSize = "1"
      InitWorker__WorkerCheckRetries = "10"       # TODO: make it a variable
      InitWorker__WorkerCheckDelay   = "00:00:10" # TODO: make it a variable
      Amqp__LinkCredit               = "2"
      Pollster__GraceDelay           = "00:00:15"
    }
    }, {
    env = var.extra_conf.polling
  }]
  materialize_configmap = {
    name      = "polling-agent-configmap"
    namespace = var.namespace
  }
}
