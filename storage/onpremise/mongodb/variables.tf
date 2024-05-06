# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Parameters for MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type = object({
    image              = string
    tag                = string
    node_selector      = map(string)
    image_pull_secrets = string
    replicas_number    = number
  })
}

variable "security_context" {
  description = "security context for MongoDB pods"
  type = object({
    run_as_user = number
    fs_group    = number
  })
  default = {
    run_as_user = 999
    fs_group    = 999
  }
}

# Persistent volume
variable "persistent_volume" {
  description = "Persistent volume info"
  type = object({
    access_mode         = optional(list(string), ["ReadWriteMany"])
    reclaim_policy      = optional(string, "Delete")
    storage_provisioner = string
    volume_binding_mode = string
    parameters          = optional(map(string), {})

    # Resources for PVC
    resources = object({
      limits = object({
        storage = string
      })
      requests = object({
        storage = string
      })
    })

    wait_until_bound = optional(bool, true)
  })
  default = null
}

variable "validity_period_hours" {
  description = "Validity period of the certificate in hours"
  type        = string
  default     = "8760" # 1 year
}
