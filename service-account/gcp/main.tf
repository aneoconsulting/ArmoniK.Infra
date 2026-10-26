data "google_client_config" "current" {}

# The workload identity pool belongs to the project of the GKE cluster
data "google_project" "cluster" {
  project_id = coalesce(var.cluster_project_id, data.google_client_config.current.project)
}

locals {
  member = "principal://iam.googleapis.com/projects/${data.google_project.cluster.number}/locations/global/workloadIdentityPools/${data.google_project.cluster.project_id}.svc.id.goog/subject/ns/${var.kubernetes_namespace}/sa/${var.kubernetes_service_account}"
}

resource "google_project_iam_member" "role" {
  for_each = var.project_roles
  project  = data.google_client_config.current.project
  role     = each.value
  member   = local.member
}
