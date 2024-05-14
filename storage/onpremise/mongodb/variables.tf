variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
  default     = "default"
}

variable "labels" {
  description = "Labels for the Kubernetes StatefulSet to be deployed"
  type        = map(string)
  default = {
    "app"  = "storage"
    "type" = "table"
  }
}

variable "helm_release_name" {
  description = "Name of the helm chart release, must be shorter than 54 characters"
  type        = string
  default     = "mongodb-armonik-helm-release"
}

variable "kube_config_path" {
  description = "Local file path of the kubernetes configuration"
  type        = string
  default     = "~/.kube/config"
}

variable "mongodb" {
  description = "Parameters of the MongoDB deployment"

  type = object({
    architecture          = optional(string, "replicaset") # "replicaset" or "standalone"
    databases_names       = optional(list(string), ["database"])
    helm_chart_repository = optional(string, "oci://registry-1.docker.io/bitnamicharts")
    helm_chart_name       = optional(string, "mongodb")
    helm_chart_version    = string
    image                 = optional(string, "bitnami/mongodb")
    image_pull_secrets    = optional(any, [""]) # can be a string or a list of strings
    node_selector         = optional(map(string), {})
    registry              = optional(string, "docker.io")
    replicas_number       = optional(number, 2)
    tag                   = string
  })
}

/* Included in the mongodb variable for retrocompatibility reasons
variable "mongodb_image" {
  description = "Image for MongoDB"
  type = object({
    image_name         = string
    image_pull_secrets = list(string)
    tag                = string
    registry           = string

  })
  default = { 
    registry           = "docker.io"
    image_name         = "bitnami/mongodb"
    image_pull_secrets = [""]
    tag                = "7.0.8-debian-12-r2"
  }
}
*/

# Not used yet (there for retrocompatibility reasons)
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

variable "mTLSEnabled" {
  description = "Whether to deploy mongo with mTLS"
  type        = bool
  default     = false
}

# Not used yet (there for retrocompatibility reasons)
variable "validity_period_hours" {
  description = "Validity period of the certificate in hours"
  type        = string
  default     = "8760" # 1 year
}
