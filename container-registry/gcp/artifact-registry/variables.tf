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



