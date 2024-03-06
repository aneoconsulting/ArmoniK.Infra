# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Type of service
variable "service_type" {
  description = "Service type which can be: ClusterIP, NodePort or LoadBalancer"
  type        = string
  default     = "ClusterIP"
}

#parameter
variable "metrics_exporter" {
  description = "Metrics_exporter service parameters"
  type = object({
    name          = optional(string, "metrics-exporter")
    label_app     = optional(string, "armonik")
    label_service = optional(string, "metrics-exporter")
    port_name     = optional(string, "metrics")
    port          = optional(number, 9419)
    target_port   = optional(number, 1080)
    protocol      = optional(string, "TCP")
  })
}
