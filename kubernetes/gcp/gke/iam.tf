# Nodes of the cluster, with the roles GKE needs
resource "google_service_account" "nodes" {
  count        = var.service_account == null ? 1 : 0
  project      = local.project
  account_id   = coalesce(var.service_account_name, "gke-${trimsuffix(substr(var.name, 0, 20), "-")}-nodes")
  display_name = "Nodes of the GKE cluster ${var.name}"
}

resource "google_project_iam_member" "nodes" {
  for_each = var.service_account == null ? local.node_roles : {}
  project  = each.value.project
  role     = each.value.role
  member   = google_service_account.nodes[0].member
}

# GKE service agent, which encrypts the Kubernetes secrets with the KMS key
resource "google_project_service_identity" "etcd" {
  count    = var.kms_key != null ? 1 : 0
  provider = google-beta
  project  = local.project
  service  = "container.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "etcd" {
  count         = var.kms_key != null ? 1 : 0
  crypto_key_id = var.kms_key.id
  member        = google_project_service_identity.etcd[0].member
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

# Compute Engine service agent, which encrypts the boot disks of the nodes with the KMS key
resource "google_project_service_identity" "boot_disk" {
  count    = var.boot_disk_kms_key != null ? 1 : 0
  provider = google-beta
  project  = local.project
  service  = "compute.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "boot_disk" {
  count         = var.boot_disk_kms_key != null ? 1 : 0
  crypto_key_id = var.boot_disk_kms_key.id
  member        = google_project_service_identity.boot_disk[0].member
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}
