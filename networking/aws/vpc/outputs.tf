output "azs" {
  description = "A list of availability zones"
  value       = module.vpc.azs
}

output "enable_external_access" {
  description = "Boolean to disable external access"
  value       = local.enable_external_access
}

output "name" {
  description = "The name of the VPC"
  value       = module.vpc.name
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = module.vpc.private_subnet_arns
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "private_subnets_details" {
  description = "Map of private subnet IDs to availability zones"
  value = {
    for i, subnet_id in module.vpc.private_subnets : subnet_id => {
      availability_zone = element(
        data.aws_availability_zones.available.names,
        i % length(data.aws_availability_zones.available.names)
      )
      cidr_block = element(
        module.vpc.private_subnets_cidr_blocks,
        i
      )
    }
  }
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = module.vpc.public_subnet_arns
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "flow_log_cloudwatch_iam_role_arn" {
  description = "The ARN of the IAM role used when pushing logs to Cloudwatch log group"
  value       = module.vpc.vpc_flow_log_cloudwatch_iam_role_arn
}

output "flow_log_destination_arn" {
  description = "The ARN of the destination for VPC Flow Logs"
  value       = module.vpc.vpc_flow_log_destination_arn
}

output "flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = module.vpc.vpc_flow_log_id
}

output "id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = module.vpc.vpc_secondary_cidr_blocks
}

output "pod_subnets_cidr_blocks" {
  description = "List of Pods subnet CIDR blocks"
  value       = var.pod_subnets
}

output "pod_subnet_arns" {
  description = "List of ARNs of Pods subnets"
  value       = [for subnet in data.aws_subnet.pod_subnets : subnet.arn]
}

output "pod_subnets" {
  description = "List of IDs of Pods subnets"
  value       = [for subnet in data.aws_subnet.pod_subnets : subnet.id]
}

output "tags" {
  description = "List of tags for VPC resources"
  value       = local.tags
}

output "eks_cluster_name" {
  description = "Name of the AWS EKS cluster"
  value       = var.eks_name
}

output "this" {
  description = "Object VPC"
  value       = module.vpc
}
