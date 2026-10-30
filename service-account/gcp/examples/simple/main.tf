# Workload Identity Federation for GKE: the role goes to the Kubernetes service account itself, created later by
# another module, with no IAM service account
module "simple_service_account" {
  source                 = "../../../gcp"
  name                   = "simple-sa"
  kubernetes_namespace   = "default"
  roles                  = ["roles/logging.logWriter"]
  create_service_account = false
  iam_service_account    = false
}
