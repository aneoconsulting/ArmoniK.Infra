variable "region" {
  description = "The GCP region used to deploy the KMS."
  type        = string
  default     = "europe-west9"
}

variable "project" {
  description = "Project name"
  type        = string
}
