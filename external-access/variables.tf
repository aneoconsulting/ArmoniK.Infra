variable "namespace" {
  description = "Kubernetes namespace in which resources will be deployed"
  type        = string
  default     = "armonik"
}

variable "cluster_domain" {
  description = "The cluster domain, used to generate the ingress certificate with the correct SANs. By default, it is extracted from the CoreDNS configmap, but can be overridden if needed."
  type        = string
  default     = null
}

variable "admin_gui" {
  description = "Parameters of the admin GUI"
  type = object({
    name  = optional(string, "admin-app")
    image = optional(string, "dockerhubaneo/armonik_admin_app")
    tag   = optional(string)
    port  = optional(number, 1080)
    limits = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    requests = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    service_type       = optional(string, "ClusterIP")
    replicas           = optional(number, 1)
    image_pull_policy  = optional(string, "IfNotPresent")
    image_pull_secrets = optional(string, "")
    node_selector      = optional(map(string), {})
    labels = optional(map(string), {
      app     = "armonik",
      service = "admin-gui"
    })
  })
  default = null
}

variable "ingress" {
  description = "Parameters of the ingress controller"
  type = object({
    name               = optional(string, "ingress")
    service_type       = optional(string, "LoadBalancer")
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
    node_selector      = optional(map(string))
    annotations        = optional(map(string))
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
      generate       = optional(bool, true)
      custom_ca_file = optional(string, "")
    }), {})
  })
  validation {
    error_message = "Ingress mTLS requires TLS to be enabled."
    condition     = !var.ingress.mtls || var.ingress.tls != "false"
  }
  validation {
    error_message = "Without TLS, http_port and grpc_port must be different."
    condition     = !var.ingress.tls ? (var.ingress.http_port != var.ingress.grpc_port) : true
  }
  validation {
    error_message = "Client certificate generation requires mTLS to be enabled."
    condition     = var.ingress.client_certs.generate ? var.ingress.mtls : true
  }
  validation {
    error_message = "Cannot generate client certificates if the client CA is custom."
    condition     = can(try(coalesce(var.ingress.client_certs.custom_ca_file))) && var.ingress.client_certs.generate ? false : true
  }
  validation {
    error_message = "English must be supported."
    condition     = contains(var.ingress.langs, "en")
  }
  validation {
    error_message = "'var.ingress.conf_type' must be equal to 'ControlPlane' or 'LoadBalancer'"
    condition     = contains(["ControlPlane", "LoadBalancer"], var.ingress.conf_type)
  }
  validation {
    error_message = "Length of 'var.ingress.name' must not exceed 10 characters"
    condition     = length(var.ingress.name) > 10 ? false : true
  }
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
  default = {}
}

variable "authentication" {
  description = "Settings of the authentication to be used by the ingress"
  type = object({
    trusted_common_names = optional(set(string), [])
    datafile             = optional(string, "")
    permissions          = optional(map(set(string)))
  })
  default = {}
}

variable "services_urls" {
  description = "Map of service names to their URLs to be used by the ingress"
  type = object({
    grafana = optional(string, "")
    seq     = optional(string, "")
  })
  default = null
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
