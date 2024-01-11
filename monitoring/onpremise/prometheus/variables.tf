# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for Prometheus"
  type = object({
    image              = string
    tag                = string
    image_pull_secrets = string
  })
}

# Node selector
variable "node_selector" {
  description = "Node selector for Prometheus"
  type        = any
  default     = {}
}

# Type of service
variable "service_type" {
  description = "Service type which can be: ClusterIP, NodePort or LoadBalancer"
  type        = string
}

# Metrics exporter url
variable "metrics_exporter_url" {
  description = "URL of metrics exporter"
  type        = string
}

variable "security_context" {
  description = "security context for MongoDB pods"
  type = object({
    run_as_user = number
    fs_group    = number
  })
}

# Persistent volume
variable "persistent_volume" {
  description = "Persistent volume info"
  type = object({
    storage_provisioner = string
    volume_binding_mode = string
    parameters          = map(string)
    # Resources for PVC
    resources = object({
      limits = object({
        storage = string
      })
      requests = object({
        storage = string
      })
    })
  })
}
