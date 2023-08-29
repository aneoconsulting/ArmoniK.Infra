# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
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

# EFS info
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
  type        = set(string)
  default     = []
}
