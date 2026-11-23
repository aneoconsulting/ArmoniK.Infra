variable "region" {
  description = "The GCP region used by the provider"
  type        = string
  default     = "europe-west9"
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "dockerhub_username" {
  description = "Docker Hub user of the token"
  type        = string
}

variable "dockerhub_token" {
  description = "Docker Hub personal access token, read-only scope is enough"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "dockerhub_token_version" {
  description = "Increment to store a new dockerhub_token"
  type        = number
  default     = 1
}
