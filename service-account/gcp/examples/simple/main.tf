# Workload Identity Federation: the roles go to the Kubernetes service account itself, no GCP service account is created
module "simple_service_account" {
  source                     = "../../../gcp"
  kubernetes_namespace       = "default"
  kubernetes_service_account = "simple-sa"
  project_roles              = ["roles/logging.logWriter"]
}
