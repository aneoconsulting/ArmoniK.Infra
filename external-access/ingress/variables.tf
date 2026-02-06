variable "namespace" {
  description = "The namespace where the ingress resources will be deployed"
  type        = string
  default     = "armonik"
}

variable "cluster_domain" {
  description = "The cluster domain used to generate the ingress certificate with the correct SANs"
  type        = string
}

variable "ingress" {
  description = "Parameters of the ingress controller"
  type = object({
    name               = optional(string, "ingress")
    service_type       = optional(string, "LoadBalancer") # Kubernetes service type, nothing to do with ArmoniK's Load Balancer !
    replicas           = optional(number, 1)
    image              = optional(string, "nginxinc/nginx-unprivileged")
    tag                = optional(string)
    image_pull_policy  = optional(string, "IfNotPresent")
    conf_type          = optional(string, "ControlPlane") # Must be 'ControlPlane' or 'LoadBalancer'
    http_port          = optional(number, 5000)
    grpc_port          = optional(number, 5001)
    limits             = optional(map(string))
    requests           = optional(map(string))
    image_pull_secrets = optional(string, "")
    node_selector      = optional(map(string), {})
    annotations        = optional(map(string), {})
    tls                = optional(bool, false)
    mtls               = optional(bool, false)
    langs              = optional(set(string), ["en"])
    cors = optional(object({
      allowed_host      = optional(string, "*")
      allowed_headers   = optional(set(string), []) # Will be added to the default cors headers.
      allowed_methods   = optional(set(string), ["GET", "POST", "OPTIONS"])
      preflight_max_age = optional(number, 1728000)
    }), {})
    underlying_endpoint = object({
      ip   = string
      port = number
    })
    labels = optional(map(string), {
      app     = "armonik",
      service = "ingress"
    })
    client_certs = optional(object({
      generate       = optional(bool, false)
      custom_ca_file = optional(string, "")
    }), {})
  })
}

variable "environment_description" {
  description = "Description of the environment deployed"
  type        = any
  default     = null
}

variable "static" {
  description = "JSON files to be served statically by the ingress"
  type        = any
  default     = {}
}

variable "certificate_authority" {
  description = "Settings of the certificate authority to be used by the ingress"
  type = object({
    generated    = optional(bool, true)
    country      = optional(string, "France")
    organization = optional(string, "ArmoniK Ingress Root (NonTrusted)")
    common_name  = optional(string, "ArmoniK Ingress Root (NonTrusted) Private Certificate Authority")
  })
  default = null
}

variable "authentication" {
  description = "Settings of the authentication to be used by the ingress"
  type = object({
    trusted_common_names = optional(set(string), [])
    datafile             = optional(string, "")
    permissions          = optional(map(set(string)))
  })
  default = null
}

variable "services_urls" {
  description = "Map of service names to their URLs to be used by the ingress"
  type = object({
    admin_gui = optional(string, "")
    grafana   = optional(string, "")
    seq       = optional(string, "")
  })
  default = {}
}

variable "shared_storage" {
  description = "Settings of the shared storage to be used by ArmoniK"
  type = object({
    type = string
    urls = object({
      service = string
      console = string
    })
  })
  default = null
}
