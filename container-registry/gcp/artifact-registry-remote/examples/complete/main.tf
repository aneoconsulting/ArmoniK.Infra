# Docker Hub token, from the tfvars, stored in Secret Manager. secret_data_wo keeps it out of the state; bump
# dockerhub_token_version to send a new token.
resource "google_secret_manager_secret" "dockerhub" {
  secret_id = "remote-complete-dockerhub"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "dockerhub" {
  secret                 = google_secret_manager_secret.dockerhub.id
  secret_data_wo         = var.dockerhub_token
  secret_data_wo_version = var.dockerhub_token_version
}

# Reads the caches, like the node service account of a GKE cluster would
resource "google_service_account" "reader" {
  account_id   = "remote-complete-reader"
  display_name = "Reader of the remote-complete pull-through caches"
}

module "complete_remote" {
  source = "../.."
  name   = "remote-complete"
  repositories = {
    dockerhub = {
      docker_hub = true
      credentials = {
        username                = var.dockerhub_username
        password_secret_version = google_secret_manager_secret_version.dockerhub.name
      }
    }
    quay      = { uri = "https://quay.io" }
    fluentbit = { uri = "https://cr.fluentbit.io", description = "Fluent Bit images" }
  }
  readers = {
    reader = google_service_account.reader.member
  }
  cleanup_older_than = "2592000s"
  labels = {
    example = "complete"
  }
}
