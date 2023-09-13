# configmap with all the variables
resource "kubernetes_config_map" "metrics_exporter_config" {
  metadata {
    name      = "metrics-exporter-configmap"
    namespace = var.namespace
  }
  data = merge({
    MongoDB__CAFile           = local.secrets.mongodb.ca_filename
    MongoDB__ReplicaSet       = "rs0"
    MongoDB__DatabaseName     = "database"
    MongoDB__DirectConnection = "false"
    MongoDB__Tls              = "true"
  }, var.extra_conf)
}
