variable "conf_list" {
  description = "List of module output with the config; in case of a conflict, the last element has precedence"
  type = list(object({
    env           = optional(map(string), {})
    env_configmap = optional(set(string), [])
    env_from_configmap = optional(map(object({
      configmap = string
      field     = string
    })), {})
    env_secret = optional(set(string), [])
    env_from_secret = optional(map(object({
      secret = string
      field  = string
    })), {})
    mount_configmap = optional(map(object({
      configmap = string
      path      = string
      subpath   = optional(string)
      mode      = optional(string, "644")
      items = optional(map(object({
        field = string
        mode  = optional(string)
      })))
    })), {})
    mount_secret = optional(map(object({
      secret  = string
      path    = string
      subpath = optional(string)
      mode    = optional(string, "644")
      items = optional(map(object({
        field = string
        mode  = optional(string)
      })))
    })), {})
  }))
}

variable "materialize_configmap" {
  description = "Set to use the aggregatior to create a config map"
  type = object({
    name      = string
    namespace = string
  })
  default = null
}
