module "simple_seaweedfs_instance" {
  source             = "../../"
  namespace          = var.namespace
  helm_chart_version = "4.52.0"
}
