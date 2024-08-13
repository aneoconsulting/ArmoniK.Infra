# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

# Elatsicache name
variable "name" {
  description = "AWS Elasticache service name"
  type        = string
  default     = "armonik-elasticache"
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

# AWS Elasticache
variable "engine" {
  description = "Name of the cache engine to be used for the clusters in this replication group"
  type        = string
  default     = "redis"
  validation {
    condition     = contains(["redis"], var.engine)
    error_message = "The only valid value for \"engine\" : \"redis\" ."
  }
}

variable "engine_version" {
  description = "Version number of the cache engine to be used for the cache clusters in this replication group"
  type        = string
  default     = "engine_version_actual"
}

variable "node_type" {
  description = "Instance class to be used"
  type        = string
  default     = "cache.r4.large"
}

variable "apply_immediately" {
  description = "Specifies whether any modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

variable "multi_az_enabled" {
  description = "Specifies whether to enable Multi-AZ Support for the replication group"
  type        = bool
  default     = false
}

variable "automatic_failover_enabled" {
  description = "Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails"
  type        = bool
  default     = false
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (primary and replicas) this replication group will have"
  type        = number
  default     = 1
}

variable "preferred_cache_cluster_azs" {
  description = "List of EC2 availability zones in which the replication group's cache clusters will be created"
  type        = list(string)
  default     = []
}

variable "data_tiering_enabled" {
  description = "Enables data tiering"
  type        = bool
  default     = false
}

variable "log_retention_in_days" {
  description = "Number of days of the retention of the logs"
  type        = number
  default     = 0
}

variable "max_memory_samples" {
  description = "Number of samples to check for every eviction"
  type        = number
  default     = null
}

variable "slow_log" {
  description = "Slow log"
  type        = string
  default     = ""
}

variable "engine_log" {
  description = "Engine type of the logs"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "AWS KMS key id"
  type        = string
  default     = null
}

variable "log_kms_key_id" {
  description = "AWS KMS key id for logs"
  type        = string
  default     = null
}

variable "object_storage_adapter" {
  description = "Name of the adapter's"
  type        = string
  default     = "ArmoniK.Adapters.Redis.ObjectStorage"
}

variable "client_name" {
  description = "Name of the redis client"
  type        = string
  default     = "ArmoniK.Core"
}

variable "instance_name" {
  description = "Name of the instance"
  type        = string
  default     = "ArmoniKRedis"
}

variable "ssl_option" {
  description = "Ssl option"
  type        = string
  default     = "true"
}
