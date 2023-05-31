# AWS EC2 Instance Terraform Variables
# EC2 Instance Variables

# AWS EC2 Instance Type
variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "c5.4xlarge"
}

# AWS EC2 Instance Key Pair
variable "instance_keypair" {
  description = "AWS EC2 Key pair that need to be associated with EC2 Instance"
  type        = string
  default     = "terraform-key"
}

variable "master_cluster" {
  type = object({
    name           = optional(string, "master")
    ami            = optional(string, null)
    instance_type  = optional(string, "m5.4xlarge")
    instance_count = optional(number, 1)
    taints         = optional(list(string))
    labels         = optional(list(string))
  })
}

# Define custom type using schema block
variable "workers_cluster" {
  type = map(object({
    name           = string
    ami            = optional(string, null)
    instance_type  = optional(string, "m5.4xlarge")
    instance_count = optional(number, 1)
    taints         = optional(list(string))
    labels         = optional(list(string))
  }))
}

variable "common_tags" {
  type    = map(string)
  default = {}
}