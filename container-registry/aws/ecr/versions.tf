provider "skopeo2" {
  destination {
    login_username = data.aws_ecr_authorization_token.current.user_name
    login_password = data.aws_ecr_authorization_token.current.password
  }
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61"
    }
    skopeo2 = {
      source  = "bsquare-corp/skopeo2"
      version = ">= 1.1.1"
    }
    generic = {
      source  = "aneoconsulting.github.io/aneoconsulting/generic"
      version = ">= 0.1.1"
    }
  }
}
