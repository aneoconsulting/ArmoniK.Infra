# configmap with all the variables
resource "kubernetes_config_map" "partition_metrics_exporter_config" {
  metadata {
    name      = "partition-metrics-exporter-configmap"
    namespace = var.namespace
  }
  data = merge({
    MongoDB__CAFile           = local.secrets.mongodb.ca_filename
    MongoDB__ReplicaSet       = "rs0"
    MongoDB__DatabaseName     = "database"
    MongoDB__DirectConnection = "false"
    MongoDB__Tls              = "true"
    MetricsExporter__Host     = "http://${local.metrics_exporter_host}"
    MetricsExporter__Port     = local.metrics_exporter_port
    MetricsExporter__Path     = "/metrics"
  }, var.extra_conf)
}
