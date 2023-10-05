# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Node selector
variable "node_selector" {
  description = "Node selector for Seq"
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

# Fluent-bit
variable "fluent_bit" {
  description = "Parameters of Fluent bit"
  type = object({
    container_name                  = string
    image                           = string
    tag                             = string
    is_daemonset                    = bool
    http_server                     = string
    http_port                       = string
    read_from_head                  = string
    read_from_tail                  = string
    image_pull_secrets              = string
    parser                          = string
    fluentbitstate_hostpath         = string #path = "/var/log/fluent-bit/state" --> for GCP | path = "/var/fluent-bit/state" --> for localhost and AWS
    varlibdockercontainers_hostpath = string #path = "/var/log/lib/docker/containers" --> for GCP | path = "/var/lib/docker/containers" --> for localhost and AWS
    runlogjournal_hostpath          = string #path = "/var/log/run/log/journal" --> for GCP | path = "/run/log/journal" --> for localhost and AWS


  })
  validation {
    condition     = contains(["apache", "apache2", "apache_error", "nginx", "json", "docker", "cri", "syslog"], var.fluent_bit.parser)
    error_message = "Valid values for Fluent-bit parsers are: \"apache\" | \"apache2\" | \"apache_error\" | \"nginx\" | \"json\" | \"docker\" | \"cri\" | \"syslog\"."
  }
}
