# AWS Elastic Filesystem Service
variable "name" {
  description = "AWS EFS name"
  type        = string
  default     = "armonik-efs"
}

variable "kms_key_id" {
  description = "Id of the KMS key"
  type        = string
  default     = null
}

variable "performance_mode" {
  description = "The file system performance mode. Can be either generalPurpose or maxIO"
  type        = string
  default     = "generalPurpose"
  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Possible values for the parameter performance_mode are \"generalPurpose\" | \"maxIO\"."
  }
}

variable "throughput_mode" {
  description = "Throughput mode for the file system. Defaults to bursting. Valid values: bursting, elastic, and provisioned. When using provisioned, also set provisioned_throughput_in_mibps"
  type        = string
  default     = "bursting"
  validation {
    condition     = contains(["bursting", "provisioned"], var.throughput_mode)
    error_message = "When using throughput_mode=\"provisioned\", also set \"provisioned_throughput_in_mibps\"."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to provisioned"
  type        = number
  default     = null
}

variable "transition_to_ia" {
  description = "Describes the period of time that a file is not accessed, after which it transitions to IA storage"
  type        = string
  default     = "AFTER_7_DAYS"
  validation {
    condition = contains([
      "AFTER_7_DAYS",
      "AFTER_14_DAYS",
      "AFTER_30_DAYS",
      "AFTER_60_DAYS",
      "AFTER_90_DAYS"
    ], var.transition_to_ia)
    error_message = "Possible values for the parameter transition_to_ia are \"AFTER_7_DAYS\" | \"AFTER_14_DAYS\" | \"AFTER_30_DAYS\", \"AFTER_60_DAYS\" | \"AFTER_90_DAYS\"."
  }
}

variable "access_point" {
  description = " A map of access point definitions to create"
  type        = list(string)
  default     = []
}

# EFS Container Storage Interface (CSI) Driver
/*variable "csi_driver" {
  description = "EFS CSI info"
  type = object({
    name               = string
    namespace          = string
    image_pull_secrets = string
    node_selector      = any
    repository         = string
    version            = string
    docker_images = object({
      efs_csi = object({
        image = string
        tag   = string
      })
      livenessprobe = object({
        image = string
        tag   = string
      })
      node_driver_registrar = object({
        image = string
        tag   = string
      })
      external_provisioner = object({
        image = string
        tag   = string
      })
    })
  })
}*/

variable "csi_driver_name" {
  description = "CSI driver name"
  type        = string
}

variable "csi_driver_namespace" {
  description = "CSI driver namespace "
  type        = string
}

variable "csi_driver_image_pull_secrets" {
  description = "CSI driver image pull secrets"
  type        = string
}

variable "csi_driver_node_selector" {
  description = "CSI driver node selector"
  type        = any
}

variable "csi_driver_repository" {
  description = "CSI driver repository"
  type        = string
}

variable "csi_driver_version" {
  description = "CSI driver version"
  type        = string
}

variable "efs_csi_image" {
  description = "EFS CSI image"
  type        = string
}

variable "efs_csi_tag" {
  description = "EFS CSI tag"
  type        = string
}

variable "livenessprobe_image" {
  description = "Livenessprobe image"
  type        = string
}

variable "livenessprobe_tag" {
  description = "Livenessporbe tag"
  type        = string
}

variable "node_driver_registrar_image" {
  description = "Node driver registrar image"
  type        = string
}

variable "node_driver_registrar_tag" {
  description = "Node driver registrar tag"
  type        = string
}

variable "external_provisioner_image" {
  description = "External provisioner image"
  type        = string
}

variable "external_provisioner_tag" {
  description = "External provisioner tag"
  type        = string
}

# VPC infos
variable "vpc_id" {
  description = "AWS VPC id"
  type        = string
}

variable "vpc_cidr_blocks" {
  description = "AWS VPC cidr block"
  type        = set(string)
}

variable "vpc_cidr_block_private" {
  description = "AWS VPC private cidr block "
  type        = set(string)
}

variable "vpc_subnet_ids" {
  description = "AWS VPC subnet ids"
  type        = set(string)
}

# EKS issuer
variable "eks_issuer" {
  description = "EKS issuer"
  type        = string
}

# Tags
variable "tags" {
  description = "Tags for EFS CSI driver"
  type        = map(string)
}
