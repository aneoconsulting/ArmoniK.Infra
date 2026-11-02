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
  member   = "serviceAccount:${google_service_account.nodes[0].email}"
}

# GKE service agent, which encrypts the Kubernetes secrets with the KMS key
resource "google_kms_crypto_key_iam_member" "etcd" {
  count         = var.kms_key != null ? 1 : 0
  crypto_key_id = var.kms_key.id
  member        = "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

# Compute Engine service agent, which encrypts the boot disks of the nodes with the KMS key
resource "google_kms_crypto_key_iam_member" "boot_disk" {
  count         = var.boot_disk_kms_key != null ? 1 : 0
  crypto_key_id = var.boot_disk_kms_key.id
  member        = "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}
