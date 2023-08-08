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

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = "../.."
}

variable "validity_period_hours" {
  description = "validity period of the certificate in hours"
  type        = string
  default     = "8760" # 1 year
}