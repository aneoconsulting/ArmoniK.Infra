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

variable "tls" {
  type = object({
    cert_path = optional(string)
    key_path  = optional(string)
  })
  default = null
  validation {
    error_message = "You cannot provide ingress a TLS cert path without providing a key path"
    condition     = can(coalesce(var.tls.cert_path)) ? can(coalesce(var.tls.key_path)) : true
  }
  validation {
    error_message = "You cannot provide ingress a TLS key path without providing a cert path"
    condition     = can(coalesce(var.tls.key_path)) ? can(coalesce(var.tls.cert_path)) : true
  }
}

variable "mtls" {
  type = object({
    generate_certs_for = optional(set(string), [])
    extra_ca_paths     = optional(set(string), [])
    trusted_cns        = optional(set(string), [])
  })
  default = null
  # validation {
  #   error_message = "Ingress mTLS requires TLS to be enabled."
  #   condition     = var.mtls != null && var.tls == null
  # }
  # validation {
  #   error_message = "Cannot generate client certificates if the client CA is custom."
  #   condition     = can(try(coalesce(var.nginx.client_certs.custom_ca_file))) && var.nginx.client_certs.generate ? false : true
  # }
  validation {
    error_message = "When enabling mTLS, if you don't generate any cert (i.e. var.mtls.generate_certs_for has 0 element), you have to provide at least a path to a custom certification authority to 'var.mtls.extra_ca_path'"
    condition     = var.mtls != null ? (length(var.mtls.generate_certs_for) > 0 ? true : length(var.mtls.extra_ca_paths) > 0) : true
  }
}

variable "gui" {
  description = "Parameters of the admin GUI"
  type = object({
    name               = optional(string, "admin-app")
    image              = optional(string, "dockerhubaneo/armonik_admin_app")
    tag                = optional(string)
    port               = optional(number, 1080)
    limits             = optional(map(string))
    requests           = optional(map(string))
    service_type       = optional(string, "ClusterIP")
    replicas           = optional(number, 1)
    image_pull_policy  = optional(string, "IfNotPresent")
    image_pull_secrets = optional(string, "")
    node_selector      = optional(map(string), {})
    labels = optional(map(string), {
      app     = "armonik",
      service = "admin-gui"
    })
    langs = optional(set(string), ["en"])
  })
  default = null
  validation {
    error_message = "English must be supported."
    condition     = contains(var.gui.langs, "en")
  }
}

variable "nginx" {
  description = "Parameters of the ingress controller"
  type = object({
    name               = optional(string, "ingress")
    replicas           = optional(number, 1)
    image              = optional(string, "nginxinc/nginx-unprivileged")
    tag                = optional(string)
    image_pull_policy  = optional(string, "IfNotPresent")
    http_port          = optional(number, 5000)
    grpc_port          = optional(number, 5001)
    limits             = optional(map(string))
    requests           = optional(map(string))
    image_pull_secrets = optional(string, "")
    node_selector      = optional(map(string))
    annotations        = optional(map(string), {})
    labels = optional(map(string), {
      app     = "armonik",
      service = "ingress"
    })
    service = optional(object({
      type        = optional(string, "LoadBalancer")
      annotations = optional(map(string), {})
    }), {})
    cors = optional(object({
      allowed_host      = optional(string, "*")
      allowed_headers   = optional(set(string), []) # Will be added to the default cors headers.
      allowed_methods   = optional(set(string), ["GET", "POST", "OPTIONS"])
      preflight_max_age = optional(number, 1728000)
    }), {})
  })
  default = {}
  validation {
    error_message = "Without TLS, http_port and grpc_port must be different."
    condition     = var.tls == null ? (var.nginx.http_port != var.nginx.grpc_port) : true
  }
  validation {
    error_message = "Length of 'var.nginx.name' must not exceed 10 characters"
    condition     = length(var.nginx.name) > 10 ? false : true
  }
  # validation {
  #   error_message = "If you don't deploy ArmoniK's Load Balancer, you must define 'var.nginx.underlying_endpoint'"
  #   condition     = can(try(coalesce(var.load_balancer))) ? true : can(try(coalesce(var.nginx.underlying_endpoint)))
  # }
}

variable "clusters" {
  type = map(object({
    endpoint = string
    cert_pem = optional(string)
    key_pem  = optional(string)
    ca_cert  = optional(string)
    # allow_unsafe_connection = optional(bool, false)
    override_target_name    = optional(string)
    pool_size               = optional(number)
    requests_per_connection = optional(number)
    multiplex               = optional(bool, false)
    fallback                = optional(bool)
    forward_headers         = optional(list(string))
    grafana_url             = optional(string)
    seq_url                 = optional(string)
    s3_urls = optional(object({
      service = string
      console = string
    }))
  }))
}

variable "default_cluster" {
  type    = string
  default = null
  # validation {
  #   error_message = "var.default_cluster is irrelevant if no cluster is provided (i.e. var.clusters is null)"
  #   condition     = can(try(coalesce(var.default_cluster))) ? can(try(coalescelist(keys(var.clusters)))) : true
  # }
  # validation {
  #   error_message = "var.default_cluster must correspond to a key of var.clusters"
  #   condition     = can(try(coalesce(var.default_cluster))) ? contains(keys(var.clusters), var.default_cluster) : true
  # }
  # validation {
  #   error_message = "var.default_cluster is irrelevant if load balancing is not enforced (i.e. if var.load_balancer not null)"
  #   condition     = can(try(coalesce(var.default_cluster))) ? var.load_balancer != null : true
  # }
}

variable "load_balancer" {
  description = "Parameters of the Load Balancer deployment"
  type = object({
    image              = optional(string, "dockerhubaneo/armonik_load_balancer")
    tag                = optional(string)
    image_pull_policy  = optional(string, "IfNotPresent")
    limits             = optional(map(string))
    requests           = optional(map(string))
    image_pull_secrets = optional(string, "")
    replicas           = optional(number, 1)
    node_selector      = optional(map(string), {})
    annotations        = optional(map(string), {})
    service = optional(object({
      type        = optional(string, "HeadLess")
      annotations = optional(map(string), {})
    }), {})
    labels = optional(map(string), {
      app     = "armonik",
      service = "load-balancer"
    })
    conf = optional(object({
      listen_ip             = optional(string)
      listen_port           = optional(number, 8081)
      refresh_delay_seconds = optional(number)
      sqlite_db_path        = optional(string)
      session_cache_size    = optional(number)
      result_cache_size     = optional(number)
      task_cache_size       = optional(number)
    }), {})
    extra_env = optional(map(string))
    # certs = optional(object({
    #   ca_path   = optional(string)
    #   cert_path = optional(string)
    #   key_path  = optional(string)
    #   }
    # ))
    # extra_volumes = optional(any)
  })
  default = null
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
