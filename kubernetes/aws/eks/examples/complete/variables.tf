# Profile
variable "aws_profile" {
  description = "Profile of AWS credentials to deploy Terraform sources"
  type        = string
  default     = "tschneider"
}

# Region
variable "aws_region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "eu-west-3"
}
