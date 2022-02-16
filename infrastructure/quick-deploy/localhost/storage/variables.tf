# Kubeconfig path
variable "k8s_config_path" {
  description = "Path of the configuration file of K8s"
  type        = string
  default     = "~/.kube/config"
}

# Kubeconfig context
variable "k8s_config_context" {
  description = "Context of K8s"
  type        = string
  default     = "default"
}

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for ArmoniK"
  type        = string
  default     = "armonik"
}

# Shared storage
variable "shared_storage" {
  description = "Shared storage infos"
  type        = object({
    host_path         = string
    file_storage_type = string
    file_server_ip    = string
  })
}

# Parameters for ActiveMQ
variable "activemq" {
  description = "Parameters of ActiveMQ"
  type        = object({
    image         = string
    tag           = string
    node_selector = any
  })
}

# Parameters for MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type        = object({
    image         = string
    tag           = string
    node_selector = any
  })
}

# Parameters for Redis
variable "redis" {
  description = "Parameters of Redis"
  type        = object({
    image         = string
    tag           = string
    node_selector = any
  })
}
