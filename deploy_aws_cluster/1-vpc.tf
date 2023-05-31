# Create a VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>4.0.1"

  name = "cluster-vpc-${var.suffix}"
  cidr = "10.0.0.0/16"

  azs = formatlist("${data.aws_region.current.name}%s", ["a", "b"])

  private_subnets = ["10.0.1.0/24" /*, "10.0.2.0/24"*/]
  public_subnets  = ["10.0.101.0/24" /*, "10.0.102.0/24"*/]

  # NAT Gateways - Outbound Communication
  enable_nat_gateway = true
  single_nat_gateway = false
  #enable_vpn_gateway = true

  # Databases subnets
  create_database_subnet_group       = false
  create_database_subnet_route_table = false
  # create_database_nat_gateway_route = true
  # create_database_internet_gateway_route = true

  # VPC DNS Parameters
  enable_dns_hostnames = true
  enable_dns_support   = true


  tags = var.common_tags
  vpc_tags = {
    "Kind" = "VPC"
  }
  public_subnet_tags = {
    "Kind" = "Public"
  }
  private_subnet_tags = {
    "Kind" = "Private"
  }
}

data "aws_region" "current" {}
