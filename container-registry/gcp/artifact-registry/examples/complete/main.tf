data "google_client_openid_userinfo" "current" {}

locals {
  current_user = "user:${data.google_client_openid_userinfo.current.email}"
}

module "complete_artifact_registry" {
  source      = "../../../artifact-registry"
  name        = "complete-test"
  description = "A complete artifact registry"
  kms_key_id  = null
  remote_repositories = {
    dockerhub = { public_repository = "DOCKER_HUB", priority = 20, description = "Docker Hub" }
    quay      = { uri = "https://quay.io", priority = 10 }
  }
  standard_repository = {
    immutable_tags = true
    priority       = 100
    iam_roles = {
      "roles/artifactregistry.writer" = [local.current_user]
    }
  }
  iam_roles = {
    "roles/artifactregistry.reader" = [local.current_user]
  }
  labels = {
    env    = "test"
    app    = "complete"
    module = "artifact-registry"
    # Label values only allow lowercase letters, digits, "_" and "-"
    created_by = replace(lower(split("@", data.google_client_openid_userinfo.current.email)[0]), "/[^a-z0-9_-]/", "_")
  }
}
