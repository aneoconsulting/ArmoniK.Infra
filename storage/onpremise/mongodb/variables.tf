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
    node_selector      = any
    image_pull_secrets = string
    replicas_number    = number
  })
}

# Persistent volume
variable "persistent_volume" {
  description = "Persistent volume info"
  type = object({
    storage_provisioner = string
    parameters          = map(string)
    # Resources for PVC
    resources = object({
      limits = object({
        storage = string
      })
      requests = object({
        storage = string
      })
    })
  })
}

variable "validity_period_hours" {
  description = "Validity period of the certificate in hours"
  type        = string
  default     = "8760" # 1 year
}
