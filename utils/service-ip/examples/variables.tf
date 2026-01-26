variable "namespace" {
  description = "Namespace where to deploy the service"
  type        = string
  default     = "default"
}

variable "type" {
  description = "Type of service to deploy"
  type        = string
}

variable "port" {
  description = "Port on which to expose the service"
  type        = number
}
