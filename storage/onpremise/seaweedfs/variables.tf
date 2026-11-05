# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

variable "name" {
  description = "Name of the helm release, also used as the chart fullname: the S3 service is <name>-all-in-one"
  type        = string
  default     = "seaweedfs"
  validation {
    # <name>-all-in-one must fit in a 63-character DNS label
    condition     = length(var.name) <= 52
    error_message = "The name must be at most 52 characters long."
  }
}

# Parameters for SeaweedFS
variable "seaweedfs" {
  description = "Parameters of the SeaweedFS S3 payload storage, deployed as a single all-in-one pod"
  type = object({
    helm_chart_repository = optional(string, "https://seaweedfs.github.io/seaweedfs/helm")
    helm_chart_name       = optional(string, "seaweedfs")
    helm_chart_version    = string
    image                 = optional(string, "chrislusf/seaweedfs")
    registry              = optional(string, "")
    tag                   = optional(string) # defaults to the chart appVersion
    image_pull_secrets    = optional(string, "")
    node_selector         = optional(map(string), {})
    bucket_name           = optional(string, "armonik")
    persistence = optional(object({
      type          = optional(string, "emptyDir")
      size          = optional(string)
      storage_class = optional(string)
    }), {})
  })
  validation {
    condition     = contains(["emptyDir", "persistentVolumeClaim"], var.seaweedfs.persistence.type)
    error_message = "seaweedfs.persistence.type must be either emptyDir or persistentVolumeClaim."
  }
}

variable "resources" {
  description = "CPU and memory limits and requests of the SeaweedFS pod, the chart defaults apply when empty"
  type = object({
    limits   = optional(map(string))
    requests = optional(map(string))
  })
  default = {}
}

variable "timeout" {
  description = "Timeout in seconds of the helm release, bucket creation hook included"
  type        = number
  default     = 300
}

variable "object_storage_adapter" {
  description = "Name of the ArmoniK adapter to use for the storage"
  type        = string
  default     = "ArmoniK.Adapters.S3.ObjectStorage"
}

variable "adapter_class_name" {
  description = "Name of the adapter's class"
  type        = string
  default     = "ArmoniK.Core.Adapters.S3.ObjectBuilder"
}

variable "adapter_absolute_path" {
  description = "The adapter's absolute path"
  type        = string
  default     = "/adapters/object/s3/ArmoniK.Core.Adapters.S3.dll"
}
