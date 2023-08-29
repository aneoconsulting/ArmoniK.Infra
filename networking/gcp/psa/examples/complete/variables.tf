variable "region" {
  description = "The GCP region to deploy the Artifact registry"
  type        = string
  default     = "europe-west1"
}

variable "project" {
  description = "Project name"
  type        = string
}
