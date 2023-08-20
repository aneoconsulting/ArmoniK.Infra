variable "region" {
  description = "The GCP region to deploy the GCS"
  type        = string
  default     = "europe-west9"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "armonik-gcp-13469"
}
