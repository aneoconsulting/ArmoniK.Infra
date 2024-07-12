# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

# MQ name
variable "name" {
  description = "AWS MQ service name"
  type        = string
  default     = "armonik-mq"
}

# VPC infos
variable "vpc_id" {
  description = "AWS VPC id"
  type        = string
}

variable "vpc_cidr_blocks" {
  description = "AWS VPC cidr block"
  type        = list(string)
}

variable "vpc_subnet_ids" {
  description = "AWS VPC subnet ids"
  type        = list(string)
}

# User credentials
variable "username" {
  description = "User name"
  type        = string
  default     = null
}

variable "password" {
  description = "User password"
  type        = string
  default     = null
}

variable "engine_type" {
  description = "AWS MQ engine type"
  type        = string
  validation {
    condition     = contains(["ActiveMQ", "RabbitMQ"], var.engine_type)
    error_message = "Valid values for \"engine_type\" : \"ActiveMQ\" | \"RabbitMQ\"."
  }
}

variable "engine_version" {
  description = "AWS MQ engine version"
  type        = string
}

variable "host_instance_type" {
  description = "AWS MQ host instance type"
  type        = string
  default     = "mq.m5.xlarge"
}

variable "apply_immediately" {
  description = "Specifies whether any broker modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

variable "deployment_mode" {
  description = "AWS MQ deployment mode"
  type        = string
  default     = "SINGLE_INSTANCE"
  validation {
    condition     = contains(["SINGLE_INSTANCE", "ACTIVE_STANDBY_MULTI_AZ", "CLUSTER_MULTI_AZ"], var.deployment_mode)
    error_message = "Valid values for \"deployment mode\" : \"SINGLE_INSTANCE\" | \"ACTIVE_STANDBY_MULTI_AZ\"| \"CLUSTER_MULTI_AZ\"."
  }
}

variable "storage_type" {
  description = "AWS MQ storage type"
  type        = string
  default     = "efs"
  validation {
    condition     = contains(["efs", "ebs"], var.storage_type)
    error_message = "Valid values for \"storage type\" : \"efs\" | \"ebs\"."
  }
}

variable "authentication_strategy" {
  description = "AWS MQ authentication strategy"
  type        = string
  validation {
    condition     = contains(["simple", "ldap"], var.authentication_strategy)
    error_message = "Valid values for \"authentication strategy\" : \"simple\" | \"ldap\"."
  }
  default = "simple"
}

variable "publicly_accessible" {
  description = "Whether to enable connections from applications outside of the VPC that hosts the broker's subnets"
  type        = bool
  default     = null
}

variable "kms_key_id" {
  description = "AWS KMS key id "
  type        = string
  default     = null
}

variable "adapter_class_name" {
  description = "Name of the adapter's class"
  type        = string
  default     = "ArmoniK.Core.Adapters.Amqp.QueueBuilder"
}

variable "adapter_absolute_path" {
  description = "The adapter's absolut path"
  type        = string
  default     = "/adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll"
}

variable "scheme" {
  description = "The scheme for the AMQP"
  type        = string
  default     = "AMQPS"
}


variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
  default     = "armonik"
}
