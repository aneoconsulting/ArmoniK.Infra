variable "region" {
  description = "the region where to create the bucket"
  type        = string
}

variable "zone" {
  description = "The zone where to create the bucket"
  type        = string
  default     = null
}

variable "project_id" {
  description = "The id project where to create the bucket"
  type        = string
}

variable "bucket_name" {
  description = "The name of the bucket."
  type        = string
}

variable "force_destroy" {
  description = "When deleting a bucket, this boolean option will delete all contained objects."
  type        = bool
  default     = false
}

variable "storage_class" {
  description = "The Storage Class of the new bucket. Supported values include: STANDARD (default), MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE."
  type        = string
  default     = "STANDARD"
}

variable "autoclass" {
  description = "The bucket's Autoclass configuration."
  type        = object({
    enabled = bool
  }) 
  default     = null
}

variable "lifecycle_rule" {
  description = "The bucket's Lifecycle Rules configuration."
  type        = object({
    action        = object({
      type          = string
      storage_class = string
    })
    condition = object ({
      age                        = optional(number)
      created_before             = optional(string)
      with_state                 = optional(string)
      matches_storage_class      = optional(list(string))
      matches_prefix             = optional(list(string))
      matches_suffix             = optional(list(string))
      num_newer_versions         = optional(number)
      custom_time_before         = optional(string)
      days_since_custom_time     = optional(string)
      days_since_noncurrent_time = optional(string)
      noncurrent_time_before     = optional(string)
    })
  })
  default     = null
}

variable "versioning" {
  description = "The bucket's Versioning configuration."
  type        = object({
    enabled = bool
  }) 
  default     = null
}

variable "website" {
  description = "Configuration if the bucket acts as a website. Structure is documented below."
  type        = object({
    main_page_suffix = optional(string)
    not_found_page   = optional(string)
  })
  default     = null
}

variable "cors" {
  description = "The bucket's Cross-Origin Resource Sharing (CORS) configuration."
  type        = object({
    origin          = optional(list(string))
    method          = optional(list(string))
    response_header = optional(list(string))
    max_age_seconds = optional(number)
  })
  default = null
}

variable "default_event_based_hold" {
  description = "Whether or not to automatically apply an eventBasedHold to new objects added to the bucket."
  type        = bool 
  default     = false 
}

variable "retention_policy" {
  description = "Configuration of the bucket's data retention policy for how long objects in the bucket should be retained."
  type        = object({
    is_locked        = optional(bool)
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
  type        = object({
    log_bucket        = string
    log_object_prefix = optional(string)
  })
  default = null
}

variable "requester_pays" {
  description = "Enables Requester Pays on a storage bucket."
  type        = bool
  default     = false
}

variable "encryption" {
  description = "The bucket's encryption configuration."
  type        = object({
    default_kms_key_name = string
  })
  default = null
}

variable "uniform_bucket_level_access" {
  description = "Enables Uniform bucket-level access access to a bucket"
  type        = bool
  default     = false
}

variable "public_access_prevention" {
  description = "Prevents public access to a bucket. Acceptable values are 'inherited' or 'enforced'"
  type        = string
  default     = "inherited"
}

variable "custom_placement_config" {
  description = "The bucket's custom location configuration, which specifies the individual regions that comprise a dual-region bucket. If the bucket is designated a single or multi-region, the parameters are empty."
  type        = object({
    data_locations = list(string)
  })
  default = null
}

variable "credentials_file" {
  description = "The credential json file"
  type        = string
  validation {
    condition     = can(regex(".*\\.json", var.credentials_file))
    error_message = "The value of credentials_file need to be a json"
  }
}

############### SECTION - Bucket acl

variable "role_entity" {
  description = "List of role/entity pairs for acls bucket"
  type        = list(string)
  default     = []
}

############### SECTION - Bucket policy

variable "policy_data" {
  description = "Policy data to bind to the bucket"
  type        = map(list(string))
  default     = null
}