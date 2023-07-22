variable "domain" {
  description = "Internal domain name of the Kubernetes cluster"
  type        = string
  default     = "cluster.local"
}

variable "service" {
  description = "Service object"
  type        = any
}
