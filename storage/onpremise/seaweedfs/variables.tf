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
variable "helm_chart_repository" {
  description = "Repository of the SeaweedFS Helm chart"
  type        = string
  default     = "https://seaweedfs.github.io/seaweedfs/helm"
}

variable "helm_chart_name" {
  description = "Name of the SeaweedFS Helm chart"
  type        = string
  default     = "seaweedfs"
}

variable "helm_chart_version" {
  description = "Version of the SeaweedFS Helm chart"
  type        = string
}

variable "image" {
  description = "SeaweedFS image name"
  type        = string
  default     = "chrislusf/seaweedfs"
}

variable "registry" {
  description = "Registry of the SeaweedFS image"
  type        = string
  default     = ""
}

variable "tag" {
  description = "Tag of the SeaweedFS image, defaults to the chart appVersion"
  type        = string
  default     = null
}

variable "image_pull_secrets" {
  description = "Image pull secret of the SeaweedFS image"
  type        = string
  default     = ""
}

variable "node_selector" {
  description = "Node selector of the SeaweedFS pod, also turned into tolerations"
  type        = map(string)
  default     = {}
}

variable "bucket_name" {
  description = "Name of the S3 bucket created for ArmoniK"
  type        = string
  default     = "armonik"
}

variable "persistence" {
  description = "Data volume of SeaweedFS: emptyDir by default, or persistentVolumeClaim; size and storage_class default to the chart and cluster defaults"
  type = object({
    type          = optional(string, "emptyDir")
    size          = optional(string)
    storage_class = optional(string)
  })
  default  = {}
  nullable = false
  validation {
    condition     = contains(["emptyDir", "persistentVolumeClaim"], var.persistence.type)
    error_message = "persistence.type must be either emptyDir or persistentVolumeClaim."
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
