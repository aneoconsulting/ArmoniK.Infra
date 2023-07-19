# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

# S3 parameters
variable "name" {
  description = "Name of S3 service"
  type        = string
  default     = "armonik-s3"
}

variable "policy" {
  description = "Text of the policy"
  type        = string
  default     = ""
}

variable "attach_policy" {
  description = " Controls if S3 bucket should have bucket policy attached (set to `true` to use value of `policy` as bucket policy)"
  type        = bool
  default     = false
}

variable "attach_deny_insecure_transport_policy" {
  description = "Controls if S3 bucket should have deny non-SSL transport policy attached"
  type        = bool
  default     = true
}

variable "attach_require_latest_tls_policy" {
  description = "Controls if S3 bucket should require the latest version of TLS"
  type        = bool
  default     = true
}

variable "attach_public_policy" {
  description = " Controls if a user defined public bucket policy will be attached (set to `false` to allow upstream to apply defaults to the bucket)"
  type        = bool
  default     = false
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Id of the KMS key"
  type        = string
  default     = null
}

variable "sse_algorithm" {
  description = "SSE algorithm to encrypt S3 object data"
  type        = string
  default     = "aws:kms"
}

variable "ownership" {
  description = "Object ownership"
  type        = string
  default     = "BucketOwnerPreferred"
}

variable "versioning" {
  description = "Enable or disable versioning"
  type        = string
  default     = "Disabled"
}
