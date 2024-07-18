variable "name" {
  description = "The name of the bucket."
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
    condition = contains([
      "STANDARD", "MULTI_REGIONAL", "REGIONAL", "NEARLINE", "COLDLINE", "ARCHIVE"
    ], var.storage_class)
    error_message = "Valid values for \"storage_class\" are: \"STANDARD\", \"MULTI_REGIONAL\", \"REGIONAL\", \"NEARLINE\", \"COLDLINE\", \"ARCHIVE\"."
  }
}

variable "autoclass" {
  description = "The bucket's Autoclass configuration."
  type        = bool
  default     = null
}

variable "lifecycle_rule" {
  description = "The bucket's lifecycle rules configuration."
  type = map(object({
    action = object({
      type          = string
      storage_class = string
    })
    condition = object({
      age                        = number
      created_before             = string
      with_state                 = string
      matches_storage_class      = list(string)
      matches_prefix             = list(string)
      matches_suffix             = list(string)
      num_newer_versions         = number
      custom_time_before         = string
      days_since_custom_time     = string
      days_since_noncurrent_time = string
      noncurrent_time_before     = string
    })
  }))
  default = null
}

variable "versioning" {
  description = "The bucket's Versioning configuration."
  type        = bool
  default     = null
}

variable "website" {
  description = "Configuration if the bucket acts as a website. Structure is documented below."
  type = object({
    main_page_suffix = string
    not_found_page   = string
  })
  default = null
}

variable "cors" {
  description = "The bucket's Cross-Origin Resource Sharing (CORS) configuration."
  type = object({
    origin          = list(string)
    method          = list(string)
    response_header = list(string)
    max_age_seconds = number
  })
  default = null
}

variable "default_event_based_hold" {
  description = "Whether or not to automatically apply an eventBasedHold to new objects added to the bucket."
  type        = bool
  default     = null
}

variable "retention_policy" {
  description = "Configuration of the bucket's data retention policy for how long objects in the bucket should be retained."
  type = object({
    is_locked        = bool
    retention_period = number
  })
  default = null
}

variable "labels" {
  description = "A map of key/value label pairs to assign to the bucket."
  type        = map(string)
  default     = {}
}

variable "logging" {
  description = "The bucket's Access & Storage Logs configuration."
  type = object({
    log_bucket        = string
    log_object_prefix = string
  })
  default = null
}

variable "default_kms_key_name" {
  description = "The id of a Cloud KMS key that will be used to encrypt objects inserted into this bucket, if no encryption method is specified."
  type        = string
  default     = null
}

variable "requester_pays" {
  description = "Enables Requester Pays on a storage bucket."
  type        = bool
  default     = null
}

variable "uniform_bucket_level_access" {
  description = "Enables Uniform bucket-level access access to a bucket"
  type        = bool
  default     = null
}

variable "public_access_prevention" {
  description = "Prevents public access to a bucket. Acceptable values are 'inherited' or 'enforced'"
  type        = string
  default     = null
  validation {
    condition     = contains(["enforced", "inherited"], coalesce(var.public_access_prevention, "enforced"))
    error_message = "Valid values for \"public_access_prevention\" are: \"enforced\" | \"inherited\"."
  }
}

variable "data_locations" {
  description = "The bucket's custom location configuration, which specifies the individual regions that comprise a dual-region bucket. If the bucket is designated a single or multi-region, the parameters are empty."
  type        = list(string)
  default     = null
}

variable "entity_bucket_access_control" {
  description = "The entity holding the permission."
  type        = string
  default     = null
}

variable "role_bucket_access_control" {
  description = "The access permission for the entity."
  type        = string
  default     = null
  validation {
    condition     = contains(["OWNER", "READER", "WRITER"], coalesce(var.role_bucket_access_control, "OWNER"))
    error_message = "Valid values for \"role_bucket_access_control\" are: \"OWNER\" | \"READER\" | \"WRITER\"."
  }
}

variable "default_acl" {
  description = "Configure this ACL to be the default ACL."
  type        = string
  default     = null
}

variable "predefined_acl" {
  description = "The canned GCS ACL to apply."
  type        = string
  default     = null
}

variable "role_entity_acl" {
  description = "List of role/entity pairs in the form \"ROLE:entity\"."
  type        = list(string)
  default     = null
}

variable "roles" {
  description = "Roles to bind to the bucket"
  type        = map(set(string))
  default     = null
}

variable "object_storage_adapter" {
  description = "Name of the ArmoniK adapter to use for the storage"
  type        = string
  default     = "ArmoniK.Adapters.S3.ObjectStorage"
}

variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
  default     = "armonik"
}

variable "username" {
  description = "Google Cloud storage access id to use as username"
  type        = string
  default     = ""
}

variable "password" {
  description = "Google Cloud storage secret to use as passeword"
  type        = string
  default     = ""
}
