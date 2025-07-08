variable "cluster_domain" {
  description = "Internal domain name of the Kubernetes cluster"
  type        = string
  default     = null
}

variable "service" {
  description = "Service object"
  type        = any
}
