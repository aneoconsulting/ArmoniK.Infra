data "google_client_config" "current" {}

resource "google_service_account" "pods" {
  account_id  = var.service_account_name
  description = "A GCP service account with the workloadIdentityUser role for ${var.service_account_name}."
  project     = data.google_client_config.current.project
}

resource "kubernetes_service_account" "pods" {
  automount_service_account_token = var.automount_service_account_token
  metadata {
    name      = var.service_account_name
    namespace = var.kubernetes_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.pods.email
    }
  }
}

resource "google_service_account_iam_member" "pods" {
  service_account_id = google_service_account.pods.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${google_service_account.pods.project}.svc.id.goog[${kubernetes_service_account.pods.metadata[0].namespace}/${kubernetes_service_account.pods.metadata[0].name}]"
}

resource "google_project_iam_member" "workload_identity_sa_bindings" {
  for_each = var.roles
  project  = google_service_account.pods.project
  role     = each.value
  member   = google_service_account.pods.member
}
