data "google_client_config" "current" {}

# Service account hardcodé pour test : test-iam-policies@pr-13958-armonik-natixis.iam.gserviceaccount.com
locals {
  existing_gcp_sa_email   = "test-iam-policies@pr-13958-armonik-natixis.iam.gserviceaccount.com"
  existing_gcp_sa_project = "pr-13958-armonik-natixis"
  gke_project             = data.google_client_config.current.project
}

resource "kubernetes_service_account" "pods" {
  automount_service_account_token = var.automount_service_account_token
  metadata {
    name      = var.name
    namespace = var.kubernetes_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = local.existing_gcp_sa_email
    }
  }
}

resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = "projects/${local.existing_gcp_sa_project}/serviceAccounts/${local.existing_gcp_sa_email}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${local.gke_project}.svc.id.goog[${var.kubernetes_namespace}/${var.name}]"
}
