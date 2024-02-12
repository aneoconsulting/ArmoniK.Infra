# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

# Parameters for nfs server

variable "nfs_server" {
  type        = string
  description = "ip nfs server"
}

variable "nfs_path" {
  type        = string
  description = "path on server"
}



# Parameters for NFS
variable "nfs_client" {
  description = "Parameters of nfs_client"
  type = object({
    image              = string
    tag                = string
    node_selector      = any
    image_pull_secrets = string
    max_memory         = string
  })
  default = {
    image              = "k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner"
    tag                = "v4.0.2"
    node_selector      = {}
    image_pull_secrets = ""
    max_memory         = ""
  }
}

# #nfs parameter for pods

# variable "nfs_mount_pod" {
#    description = "Path to which the NFS will be mounted in the pods"
#    type = string
#    default ="/local_storage"
# }

variable "pvc_name" {
  description = "Name for the pvc to be created and used"
  type        = string
  default     = "nfsvolume"
}