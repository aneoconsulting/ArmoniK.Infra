data "google_client_config" "current" {}

# The workload identity pool belongs to the project of the GKE cluster
data "google_project" "cluster" {
  count      = var.iam_service_account ? 0 : 1
  project_id = coalesce(var.cluster_project_id, data.google_client_config.current.project)
}

locals {
  member = var.iam_service_account ? google_service_account.pods[0].member : "principal://iam.googleapis.com/projects/${data.google_project.cluster[0].number}/locations/global/workloadIdentityPools/${data.google_project.cluster[0].project_id}.svc.id.goog/subject/ns/${var.kubernetes_namespace}/sa/${var.name}"
}

resource "google_service_account" "pods" {
  count       = var.iam_service_account ? 1 : 0
  account_id  = var.name
  description = "A GCP service account with the workloadIdentityUser role for ${var.name}."
  project     = data.google_client_config.current.project
}

resource "kubernetes_service_account" "pods" {
  count                           = var.create_service_account ? 1 : 0
  automount_service_account_token = var.automount_service_account_token
  metadata {
    name      = var.name
    namespace = var.kubernetes_namespace
    annotations = var.iam_service_account ? {
      "iam.gke.io/gcp-service-account" = google_service_account.pods[0].email
    } : {}
  }
}

resource "google_service_account_iam_member" "pods" {
  count              = var.iam_service_account ? 1 : 0
  service_account_id = google_service_account.pods[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${google_service_account.pods[0].project}.svc.id.goog[${var.kubernetes_namespace}/${var.name}]"
}

resource "google_project_iam_member" "workload_identity_sa_bindings" {
  for_each = var.roles
  project  = data.google_client_config.current.project
  role     = each.value
  member   = local.member
}
