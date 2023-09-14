variable "region" {
  description = "The GCP region to deploy the Memorystore for Memcached Instance."
  type        = string
  default     = "europe-west9"
}

variable "project" {
  description = "Project name"
  type        = string
}
