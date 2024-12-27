# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

# Parameters for minio
variable "minio" {
  description = "Parameters of S3 payload storage"
  type = object({
    image              = string
    tag                = string
    image_pull_secrets = string
    host               = string
    bucket_name        = string
    node_selector      = any
  })
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
