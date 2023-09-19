# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

# Parameters for ActiveMQ
variable "activemq" {
  description = "Parameters of ActiveMQ"
  type = object({
    image              = string
    tag                = string
    node_selector      = any
    image_pull_secrets = string
  })
}

variable "validity_period_hours" {
  description = "Validity period of the certificate in hours"
  type        = string
  default     = "8760" # 1 year
}

variable "adapter_class_name" {
  description = "Name of the adapter's class"
  type        = string
}

variable "adapter_absolute_path" {
  description = "The adapter's absolut path"
  type        = string
}
