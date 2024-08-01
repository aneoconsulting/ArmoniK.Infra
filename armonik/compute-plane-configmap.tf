# configmap with all the variables
# resource "kubernetes_config_map" "compute_plane_config" {
#   metadata {
#     name      = "compute-plane-configmap"
#     namespace = var.namespace
#   }
#   data = merge({
#     ComputePlane__WorkerChannel__Address    = "/cache/armonik_worker.sock"
#     ComputePlane__WorkerChannel__SocketType = "unixdomainsocket"
#     ComputePlane__AgentChannel__Address     = "/cache/armonik_agent.sock"
#     ComputePlane__AgentChannel__SocketType  = "unixdomainsocket"
#   }, var.extra_conf.compute)
# }

module "compute_aggregation" {
  source = "../utils/aggregator"
  conf_list = [{
    env = merge({
      ComputePlane__WorkerChannel__Address    = "/cache/armonik_worker.sock"
      ComputePlane__WorkerChannel__SocketType = "unixdomainsocket"
      ComputePlane__AgentChannel__Address     = "/cache/armonik_agent.sock"
      ComputePlane__AgentChannel__SocketType  = "unixdomainsocket"
    }, var.extra_conf.compute)
  }]
  materialize_configmap = {
    name      = "compute-plane-configmap"
    namespace = var.namespace
  }
}
