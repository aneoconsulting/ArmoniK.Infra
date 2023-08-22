variable "kms_key_name" {
  description = "KMS key name to encrypt GCP repositories. Has the form: projects/{{my-project}}/locations/{{my-region}}/keyRings/{{my-kr}}/cryptoKeys/{{my-key}}"
  type        = string
  default     = null
}

variable "name" {
  description = "Name of the registry to create"
  type        = string
}

variable "labels" {
  description = "Labels for the registry"
  type        = map(string)
  default     = {}
}

variable "docker_images" {
  description = "Docker container images to push inside the registry"
  type = map(object({
    image = string
    tag   = string
  }))
}

variable "description" {
  description = "Description of the registry"
  type        = string
  default     = ""
}

variable "immutable_tags" {
  description = "If the registry is a docker format then tags can be immutable (true or false)"
  type        = bool
  default     = true
}

variable "iam_bindings" {
  description = "Assign role on the repository for a list of users"
  type        = map(list(string))
  default     = {}
}


######## SECTION - Service Account 

variable "create_service_account" {
  description = "Set to true if you need the service account for artifact registry to be created also. (Default: false)"
  type        = bool 
  default     = false
}

variable "service_account_id" {
  description = "The account id that is used to generate the service account email address and a stable unique id. Only if var.create_service_account is set to true."
  type        = string 
  validation {
    condition     =  var.service_account_id == null || can(regex("[a-z]([-a-z0-9]*[a-z0-9])", var.service_account_id))
    error_message = "The ID must be 6-30 characters long, and match the regular expression [a-z]([-a-z0-9]*[a-z0-9])"
  }
  default     = null
}

variable "service_account_display_name" {
  description = "The display name for the service account. Can be updated without creating a new resource."
  type        = string
  default     = null
}

variable "service_account_description" {
  description = "A text description of the service account."
  type        = string
  default     = null
}