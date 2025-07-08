# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}
variable "name" {
  description = "Name of the queue storage"
  type        = string
  default     = "activemq"
}
# Parameters for ActiveMQ
variable "activemq" {
  description = "Parameters of ActiveMQ"
  type = object({
    image                = string
    tag                  = string
    node_selector        = any
    image_pull_secrets   = string
    limits               = optional(map(string))
    requests             = optional(map(string))
    activemq_opts_memory = optional(string)
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
  default     = "ArmoniK.Core.Adapters.Amqp.QueueBuilder"
}

variable "adapter_absolute_path" {
  description = "The adapter's absolut path"
  type        = string
  default     = "/adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll"
}

variable "scheme" {
  description = "The scheme for the AMQP"
  type        = string
  default     = "AMQPS"
  validation {
    condition     = var.scheme == "AMQPS"
    error_message = "The scheme must be AMQPS"
  }
}

variable "path" {
  description = "Path for mounting secrets"
  type        = string
  default     = "/amqp"
}

variable "queue_storage_adapter" {
  description = "Name of the adapter's"
  type        = string
  default     = "ArmoniK.Adapters.Amqp.ObjectStorage"
}
