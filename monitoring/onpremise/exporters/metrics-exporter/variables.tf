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
variable "name" {
  description = "Service name"
  type        = string
  default     = "metrics-exporter"
}
variable "label_app" {
  description = "Service label app"
  type        = string
  default     = "armonik"
}
variable "label_service" {
  description = "Service label service type"
  type        = string
  default     = "metrics-exporter"
}

variable "port_name" {
  description = "Service port name"
  type        = string
  default     = "metrics"
}
variable "port" {
  description = "Service port"
  type        = number
  default     = 9419
}

variable "target_port" {
  description = "Service target port"
  type        = number
  default     = 1080
}
