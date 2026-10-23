variable "region" {
  description = "The GCP region of the Artifact Registry repositories"
  type        = string
  default     = "europe-west9"
}

variable "project" {
  description = "Project name"
  type        = string
}
