# configmap with all the variables
resource "kubernetes_config_map" "jobs_in_database_config" {
  metadata {
    name      = "jobs-in-database-configmap"
    namespace = var.namespace
  }
  data = var.jobs_in_database_extra_conf
}
