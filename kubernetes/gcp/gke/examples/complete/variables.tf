variable "region" {
  description = "The GCP region used by the provider."
  type        = string
  default     = "europe-west9"
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "authorized_cidr_block" {
  description = "CIDR block allowed to reach the public endpoint of the control plane, such as <your public IP>/32."
  type        = string
}
