# Namespace
variable "namespace" {
  description = "Namespace for rabbitmq"
  type        = string
}
variable "name" {
  description = "Name of the queue storage"
  type        = string
  default     = "rabbitmq"
}
variable "image" {
  description = "image for the rabbirmq to be used"
  type        = string
  default     = "bitnamilegacy/rabbitmq"
}
variable "tag" {
  description = "tag for the image"
  type        = string
  default     = "3.12.12-debian-11-r21"
}

# Repository of RabbitMQ helm chart
variable "helm_chart_repository" {
  description = "Path to helm chart repository for RabbitMQ"
  type        = string
}

# Version of helm chart
variable "helm_chart_version" {
  description = "Version of chart helm for RabbitMQ"
  type        = string
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
