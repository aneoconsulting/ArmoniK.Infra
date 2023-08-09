variable "project_id" {
  description = "Project name"
  type        = string
  default     = "armonik-gcp-13469"
}

variable "region" {
  type    = string
  default = "europe-west9"
}

variable "roles" {
  type    = list(string)
  default = ["roles/redis.editor", "roles/pubsub.editor"]
}

variable "image" {
  type = string
  description = "Container image for pod"
  default = "google/cloud-sdk:slim"
}