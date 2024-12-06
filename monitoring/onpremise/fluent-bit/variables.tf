# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Node selector
variable "node_selector" {
  description = "Node selector for fluent-bit on linux"
  type        = any
  default     = {}
}
variable "node_selector_windows" {
  description = "Node selector for fluent-bit on windows"
  type        = any
  default     = {}
}

# Seq
variable "seq" {
  description = "Seq info"
  type        = any
  default     = {}
}

# CloudWatch
variable "cloudwatch" {
  description = "CloudWatch info"
  type        = any
  default     = {}
}

# S3
variable "s3" {
  description = "S3 for logs"
  type        = any
  default     = {}
}

variable "aws" {
  description = "AWS user for logs, prefer to pass them through env('AWS_*') in your parameters.tfvars"
  type = object({
    aws_secret_access_key = optional(string, "")
    aws_access_id         = optional(string, "")
    aws_session_token     = optional(string, "")
  })
  default = {}
}

# Fluent-bit
variable "fluent_bit" {
  description = "Parameters of Fluent bit"
  type = object({
    container_name                     = string
    image                              = string
    tag                                = string
    is_daemonset                       = bool
    http_server                        = string
    http_port                          = string
    read_from_head                     = string
    read_from_tail                     = string
    image_pull_secrets                 = string
    parser                             = string
    fluent_bit_state_hostpath          = string # path = "/var/log/fluent-bit/state" for GCP Autopilot | path = "/var/fluent-bit/state" for localhost, AWS EKS, GCP GKE
    var_lib_docker_containers_hostpath = string # path = "/var/log/lib/docker/containers" for GCP Autopilot | path = "/var/lib/docker/containers" for localhost, AWS EKS, GCP GKE
    run_log_journal_hostpath           = string # path = "/var/log/run/log/journal" -for GCP Autopilot | path = "/run/log/journal" for localhost, AWS EKS, GCP GKE
  })
  validation {
    condition     = contains(["apache", "apache2", "apache_error", "nginx", "json", "docker", "cri", "syslog"], var.fluent_bit.parser)
    error_message = "Valid values for Fluent-bit parsers are: \"apache\" | \"apache2\" | \"apache_error\" | \"nginx\" | \"json\" | \"docker\" | \"cri\" | \"syslog\"."
  }
}

variable "fluent_bit_windows" {
  description = "Parameters of Fluent bit for windows"
  type = object({
    container_name                     = string
    image                              = string
    tag                                = string
    is_daemonset                       = bool
    http_server                        = string
    http_port                          = string
    read_from_head                     = string
    read_from_tail                     = string
    image_pull_secrets                 = string
    parser                             = string
    fluent_bit_state_hostpath          = string
    var_lib_docker_containers_hostpath = string
    run_log_journal_hostpath           = string
  })
  validation {
    condition     = contains(["apache", "apache2", "apache_error", "nginx", "json", "docker", "cri", "syslog"], var.fluent_bit_windows.parser)
    error_message = "Valid values for Fluent-bit parsers are: \"apache\" | \"apache2\" | \"apache_error\" | \"nginx\" | \"json\" | \"docker\" | \"cri\" | \"syslog\"."
  }
}
