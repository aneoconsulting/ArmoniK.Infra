variable "authentication" {
  description = "Settings of the authentication to be used by the ingress"
  type = object({
    trusted_common_names = optional(set(string), [])
    datafile             = optional(string, "")
    permissions          = optional(map(set(string)))
  })
  default = {}
  validation {
    error_message = "You must either provide an authentication datafile or permissions for authentication data to be proceeded"
    condition     = can(try(coalesce(var.authentication.datafile), coalesce(var.authentication.permissions)))
  }
}

variable "client_certificates" {
  description = "Client certificates needed to create authentication data"
  type        = any
}

variable "client_certs_requests" {
  description = "Client certs requests needed to retrieve common names"
  type        = any
}
