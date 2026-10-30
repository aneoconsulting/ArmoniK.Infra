variable "project" {
  description = "Project name"
  type        = string
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
  default     = "europe-west9"
}
