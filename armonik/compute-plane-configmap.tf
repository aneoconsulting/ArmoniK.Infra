# configmap with all the variables
module "compute_aggregation" {
  source = "../utils/aggregator"
  conf_list = [
    {
      env = {
        ComputePlane__WorkerChannel__Address    = "/cache/armonik_worker.sock"
        ComputePlane__WorkerChannel__SocketType = "unixdomainsocket"
        ComputePlane__AgentChannel__Address     = "/cache/armonik_agent.sock"
        ComputePlane__AgentChannel__SocketType  = "unixdomainsocket"
      }
    },
    {
      env = var.extra_conf.compute
    }
  ]
  materialize_configmap = {
    name      = "compute-plane-configmap"
    namespace = var.namespace
  }
}
