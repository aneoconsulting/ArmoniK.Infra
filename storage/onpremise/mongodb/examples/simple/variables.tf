variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
  default     = "default"
}

variable "kube_config_path" {
  description = "The kubernetes configuration file path you want to specify"
  type        = string
  default     = "~/.kube/config"
}
