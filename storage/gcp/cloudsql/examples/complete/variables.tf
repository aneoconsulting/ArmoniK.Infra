variable "region" {
  description = "The GCP region used by the provider"
  type        = string
  default     = "europe-west9"
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "network" {
  description = "VPC of the clients, projects/<project>/global/networks/<name>"
  type        = string
}

variable "psc_subnets" {
  description = "Subnets of network where the Private Service Connect endpoints take their IP address"
  type        = list(string)
}
