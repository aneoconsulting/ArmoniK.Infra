# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

# Parameters for nfs server
variable "server" {
  type        = string
  description = "ip nfs server"
}

variable "path" {
  type        = string
  description = "path on server"
}

variable "size" {
  type        = string
  description = "storage request size"
  default     = "5Gi"
}

# Parameters for NFS
variable "image" {
  description = "image for the external client provisioner"
  type        = string
  default     = "k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner"
}

variable "tag" {
  description = "tag for the image"
  type        = string
  default     = "v4.0.2"
}

variable "node_selector" {
  description = "selectors"
  type        = any
  default     = {}
}

variable "image_pull_secrets" {
  description = "pull secrets if needed"
  type        = string
  default     = ""
}

variable "image_policy" {
  description = "policy  for getting the image"
  type        = string
  default     = "IfNotPresent"
}

variable "pvc_name" {
  description = "Name for the pvc to be created and used"
  type        = string
  default     = "nfsvolume"
}

variable "object_storage_adapter" {
  description = "Name of the adapter's"
  type        = string
  default     = "ArmoniK.Adapters.LocalStorage.ObjectStorage"
}

variable "mount_path" {
  description = "Path to mount in pods"
  type        = string
  default     = "/local_storage"
}

variable "adapter_class_name" {
  description = "Name of the adapter's class"
  type        = string
  default     = "ArmoniK.Core.Adapters.LocalStorage.ObjectBuilder"
}

variable "adapter_absolute_path" {
  description = "The adapter's absolute path"
  type        = string
  default     = "/adapters/object/local_storage/ArmoniK.Core.Adapters.LocalStorage.dll"
}
