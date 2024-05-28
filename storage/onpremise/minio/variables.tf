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
