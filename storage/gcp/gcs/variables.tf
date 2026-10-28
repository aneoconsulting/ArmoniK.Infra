variable "name" {
  description = "The name of the bucket, unique across all of GCP."
  type        = string
}

variable "location" {
  description = "Location for the bucket: regional, dual-regional or multi-regional [GCS locations](https://cloud.google.com/storage/docs/locations)."
  type        = string
}

variable "force_destroy" {
  description = "When deleting a bucket, this boolean option will delete all contained objects."
  type        = bool
  default     = false
}

variable "storage_class" {
  description = "The Storage Class of the new bucket."
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Valid values for \"storage_class\" are: \"STANDARD\", \"NEARLINE\", \"COLDLINE\", \"ARCHIVE\"."
  }
}

variable "autoclass" {
  description = "The bucket's Autoclass configuration. Incompatible with lifecycle rules that change the storage class."
  type        = bool
  default     = null
  validation {
    condition     = var.autoclass != true || !anytrue([for rule in values(var.lifecycle_rule) : rule.action.type == "SetStorageClass"])
    error_message = "\"autoclass\" cannot be combined with a \"SetStorageClass\" lifecycle rule."
  }
}

variable "lifecycle_rule" {
  description = "The bucket's lifecycle rules configuration, keyed by rule name."
  type = map(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                        = optional(number)
      created_before             = optional(string)
      with_state                 = optional(string)
      matches_storage_class      = optional(list(string))
      matches_prefix             = optional(list(string))
      matches_suffix             = optional(list(string))
      num_newer_versions         = optional(number)
      custom_time_before         = optional(string)
      days_since_custom_time     = optional(number)
      days_since_noncurrent_time = optional(number)
      noncurrent_time_before     = optional(string)
    })
  }))
  default  = {}
  nullable = false
}

variable "versioning" {
  description = "The bucket's Versioning configuration. Incompatible with a retention policy."
  type        = bool
  default     = null
}

variable "retention_policy" {
  description = "Configuration of the bucket's data retention policy for how long objects in the bucket should be retained, `retention_period` in seconds."
  type = object({
    is_locked        = optional(bool, false)
    retention_period = string
  })
  default = null
  validation {
    condition     = var.retention_policy == null || var.versioning != true
    error_message = "\"retention_policy\" cannot be combined with \"versioning\"."
  }
}

# The ArmoniK object storage bucket deletes temporary results all the time: set 0 there to stop paying for them
# 7 more days. Keep the default for buckets whose objects are worth recovering, such as the worker DLLs.
variable "soft_delete_retention_days" {
  description = "Days during which deleted objects stay recoverable, and billed. 0 disables soft delete. Null keeps the server value (7 days by default); going back to null after setting it does not restore 7 days, set 7 explicitly."
  type        = number
  default     = null
}

variable "labels" {
  description = "A map of key/value label pairs to assign to the bucket."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "logging" {
  description = "The bucket's Access & Storage Logs configuration."
  type = object({
    log_bucket        = string
    log_object_prefix = optional(string)
  })
  default = null
}

variable "kms_key" {
  description = "Cloud KMS key that encrypts the objects inserted into this bucket, if no encryption method is specified. An object, so that the key can be created in the same apply: its ID is unknown at plan time, the object is not."
  type = object({
    id = string
  })
  default = null
}

variable "public_access_prevention" {
  description = "Prevents public access to a bucket. Acceptable values are 'enforced' or 'inherited' (follows the organization policy)."
  type        = string
  default     = "enforced"
  validation {
    condition     = contains(["enforced", "inherited"], var.public_access_prevention)
    error_message = "Valid values for \"public_access_prevention\" are: \"enforced\" | \"inherited\"."
  }
}

variable "data_locations" {
  description = "The bucket's custom location configuration, which specifies the individual regions that comprise a dual-region bucket. If the bucket is designated a single or multi-region, the parameters are empty."
  type        = list(string)
  default     = null
}

variable "roles" {
  description = "Roles to bind on the bucket, as a map of role to members."
  type        = map(set(string))
  default     = {}
  nullable    = false
}
