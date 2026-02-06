variable "namespace" {
  description = "The namespace where the ingress resources will be deployed"
  type        = string
  default     = "armonik"
}

variable "cluster_domain" {
  description = "The cluster domain, used to generate the ingress certificate with the correct SANs. By default, it is extracted from the CoreDNS configmap, but can be overridden if needed."
  type        = string
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
  default = {}
}
