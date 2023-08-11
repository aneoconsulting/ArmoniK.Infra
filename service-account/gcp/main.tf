resource "google_service_account" "pods" {
  account_id  = var.gcp_sa_name
  project     = var.project_id
  description = "A gcp service account with the workloadIdentityUser role"
}

resource "kubernetes_service_account" "pods" {
  automount_service_account_token = var.automount_service_account_token
  metadata {
    name      = var.k8s_sa_name
    namespace = var.K8s_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.pods.email
    }
  }
}

resource "kubernetes_namespace" "pods" {
  metadata {
    name = var.K8s_namespace
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
