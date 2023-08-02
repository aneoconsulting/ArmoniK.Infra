variable "region" {
  description = "The GCP region used to deploy NAT routers if used"
  type        = string
  default     = "europe-west9"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "armonik-gcp-13469"
}