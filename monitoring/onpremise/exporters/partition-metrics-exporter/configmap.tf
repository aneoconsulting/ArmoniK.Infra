# configmap with all the variables
module "partition_exporter_aggregation" {
  source = "../../../../utils/aggregator"
  conf_list = [{
    env = merge({
      MetricsExporter__Host = "http://${local.metrics_exporter_host}"
      MetricsExporter__Port = local.metrics_exporter_port
      MetricsExporter__Path = "/metrics"
    }, var.extra_conf)
  }]
  materialize_configmap = {
    name      = "partition-metrics-exporter-configmap"
    namespace = var.namespace
  }
}
