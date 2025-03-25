variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
  default     = "default"
}

variable "default_labels" {
  description = "Default labels for the MongoDB-related Kubernetes pods"
  type        = map(string)
  default = {
    "app"  = "storage"
    "type" = "table"
  }
}

variable "labels" {
  description = "Custom labels for the different MongoDB entities"
  type = object({
    shards    = optional(map(string))
    arbiter   = optional(map(string))
    configsvr = optional(map(string))
    router    = optional(map(string))
  })
  default = null
}

variable "name" {
  description = "Name used for the helm chart release and the associated resources, must be shorter than 54 characters"
  type        = string
  default     = "mongodb-sharded" # Ideally not change it, cause it makes the create kube service name hard to manage
  # resulting in a false connection string output
}

variable "mongodb" {
  description = "Parameters of the MongoDB deployment"

  type = object({
    database_name         = optional(string, "database")
    helm_chart_repository = optional(string, "oci://registry-1.docker.io/bitnamicharts")
    helm_chart_name       = optional(string, "mongodb-sharded")
    helm_chart_version    = string
    image                 = optional(string, "bitnami/mongodb-sharded")
    image_pull_secrets    = optional(any, [""]) # can be a string or a list of strings
    node_selector         = optional(map(string), {})
    registry              = optional(string)
    service_port          = optional(number, 27017)
    tag                   = string
  })

  validation {
    condition     = var.mongodb.service_port >= 0 && var.mongodb.service_port < 65536
    error_message = "MongoDB service port must be a number between 0 included and 65535 included"
  }
}

variable "sharding" {
  description = "Parameters specific to the sharded architecture"
  type = object({
    shards = optional(object({
      quantity      = optional(number, 2)
      replicas      = optional(number, 1)
      node_selector = optional(map(string))
    }))

    arbiter = optional(object({
      node_selector = optional(map(string))
    }))

    router = optional(object({
      replicas      = optional(number, 1)
      node_selector = optional(map(string))
    }))

    configsvr = optional(object({
      replicas      = optional(number, 1)
      node_selector = optional(map(string))
    }))
  })
  default = {
    shards    = {}
    arbiter   = {}
    router    = {}
    configsvr = {}
  }
}

variable "resources" {
  description = "Resources requests and limitations (cpu, memory, ephemeral-storage) for different types of MongoDB entities"
  type = object({
    shards = optional(object({
      limits   = optional(map(string))
      requests = optional(map(string))
    }))

    arbiter = optional(object({
      limits   = optional(map(string))
      requests = optional(map(string))
    }))

    configsvr = optional(object({
      limits   = optional(map(string))
      requests = optional(map(string))
    }))

    router = optional(object({
      limits   = optional(map(string))
      requests = optional(map(string))
    }))
  })
  default = {
    shards    = {}
    arbiter   = {}
    router    = {}
    configsvr = {}
  }
}

variable "persistence" {
  description = "Persistence parameters for MongoDB"
  type = object({
    shards = optional(object({
      access_mode         = optional(list(string), ["ReadWriteOnce"])
      reclaim_policy      = optional(string, "Delete")
      storage_provisioner = optional(string)
      volume_binding_mode = optional(string, "WaitForFirstConsumer")
      parameters          = optional(map(string), {})

      resources = optional(object({
        limits = optional(object({
          storage = string
        }))
        requests = optional(object({
          storage = string
        }))
      }))
    }))

    configsvr = optional(object({
      access_mode         = optional(list(string), ["ReadWriteOnce"])
      reclaim_policy      = optional(string, "Delete")
      storage_provisioner = optional(string)
      volume_binding_mode = optional(string, "WaitForFirstConsumer")
      parameters          = optional(map(string), {})

      resources = optional(object({
        limits = optional(object({
          storage = string
        }))
        requests = optional(object({
          storage = string
        }))
      }))
    }))
  })
  default = null
}

variable "security_context" {
  description = "Security context for MongoDB pods"
  type = object({
    run_as_user = number
    fs_group    = number
  })
  default = {
    run_as_user = 999
    fs_group    = 999
  }
}

variable "timeout" {
  description = "Timeout limit in seconds per shard for the helm release creation"
  type        = number
  default     = 180
}

variable "validity_period_hours" {
  description = "Validity period of the TLS certificate in hours"
  type        = string
  default     = "8760" # 1 year
}
