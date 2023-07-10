variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

variable "name" {
  description = "value"
  type        = string
  default     = "activemq"
}

variable "image" {
  description = "images of services"
  type        = string
  default     = "symptoma/activemq"
}

variable "tag" {
  description = "tag of images"
  type        = string
  default     = "5.17.0"
}

variable "node_selector" {
  description = "Specify node selector for pod"
  type        = map(string)
  default     = {}
}

variable "image_pull_secrets" {
  description = "(Optional) Specify list of pull secrets"
  type        = map(string)
  default     = {}
}

variable "kub_config_context" {
  description = "value"
  type        = string
}

variable "kub_config_path" {
  description = "value"
  type        = string
}
