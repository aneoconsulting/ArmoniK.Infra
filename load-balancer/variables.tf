variable "namespace" {
  description = "Kubernetes namespace where the Load Balancer resources will be created"
  type        = string
  default     = "armonik"
}

variable "cluster_domain" {
  description = "Kubernetes cluster domain used to generate the ingress certificate with the correct SANs"
  type        = string
  default     = null
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

variable "clusters_config" {
  description = "Configuration of the clusters to be load balanced"
  type = map(object({
    endpoint                = string
    cert_pem                = optional(string)
    key_pem                 = optional(string)
    ca_cert                 = optional(string)
    allow_unsafe_connection = optional(bool, false)
    override_target_name    = optional(string)
    pool_size               = optional(number)
    requests_per_connection = optional(number)
    multiplex               = optional(bool, false)
    fallback                = optional(bool, false)
    forward_headers         = optional(list(string))
  }))
}

variable "load_balancer" {
  description = "Parameters of the Load Balancer deployment"
  type = object({
    image              = optional(string, "dockerhubaneo/armonik_load_balancer")
    tag                = optional(string)
    port               = optional(number, 1080)
    image_pull_policy  = optional(string, "IfNotPresent")
    limits             = optional(map(string))
    requests           = optional(map(string))
    image_pull_secrets = optional(string, "")
    replicas           = optional(number, 1)
    service_type       = optional(string, "ClusterIP")
    node_selector      = optional(map(string), {})
    annotations        = optional(map(string), {})
    labels = optional(map(string), {
      app     = "armonik",
      service = "load-balancer"
    })
    config = optional(object({
      listen_ip             = optional(string)
      listen_port           = optional(number)
      refresh_delay_seconds = optional(number)
      sqlite_db_path        = optional(string)
      session_cache_size    = optional(number)
      result_cache_size     = optional(number)
      task_cache_size       = optional(number)
    }), null)
    rust_log = optional(string)
  })
  default = {}
}

variable "ingress" {
  description = "Parameters of the ingress controller"
  type = object({
    name               = optional(string, "lb-ingress")
    replicas           = optional(number, 1)
    image              = optional(string, "nginxinc/nginx-unprivileged")
    tag                = optional(string)
    image_pull_policy  = optional(string, "IfNotPresent")
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
    labels = optional(map(string), {
      app     = "armonik",
      service = "load-balancer"
    })
    client_certs = optional(object({
      generate       = optional(bool, false)
      custom_ca_file = optional(string, "")
    }), {})
  })
  default = {}
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

variable "certificate_authority" {
  description = "Settings of the certificate authority to be used by the ingress"
  type = object({
    generated    = optional(bool, true)
    country      = optional(string, "France")
    organization = optional(string, "ArmoniK Load Balancer Ingress Root (NonTrusted)")
    common_name  = optional(string, "ArmoniK Load Balancer Ingress Root (NonTrusted) Private Certificate Authority")
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
