output "arn" {
  description = "ARN of EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "aws_eks_module" {
  description = "aws eks module"
  value       = module.eks
}

output "cluster_certificate_authority_data" {
  description = "cluster_certificate_authority_data"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "kms_key_id" {
  description = "ARN of KMS used for EKS"
  value = {
    cluster_log_kms_key_id    = var.cluster_log_kms_key_id
    cluster_encryption_config = var.cluster_encryption_config
    ebs_kms_key_id            = var.ebs_kms_key_id
  }
}

output "self_managed_worker_iam_role_names" {
  description = "list of the self managed workers IAM role names"
  value       = values(module.eks.self_managed_node_groups)[*].iam_role_name
}

output "eks_managed_worker_iam_role_names" {
  description = "list of the EKS managed workers IAM role names"
  value       = values(module.eks.eks_managed_node_groups)[*].iam_role_name
}

output "fargate_profiles_worker_iam_role_names" {
  description = "list of the fargate profile workers IAM role names"
  value       = values(module.eks.fargate_profiles)[*].iam_role_name
}

output "worker_iam_role_names" {
  description = "list of the workers IAM role names"
  value = compact(flatten(concat(
    values(module.eks.eks_managed_node_groups)[*].iam_role_name,
    values(module.eks.self_managed_node_groups)[*].iam_role_name,
  values(module.eks.fargate_profiles)[*].iam_role_name)))
}

output "cluster_iam_role_name" {
  description = "Cluster IAM role name"
  value       = module.eks.cluster_iam_role_name
}

output "eks_managed_node_groups" {
  description = "List of EKS managed group nodes"
  value       = module.eks.eks_managed_node_groups
}

output "self_managed_node_groups" {
  description = "List of self managed node groups"
  value       = module.eks.self_managed_node_groups
}

output "fargate_profiles" {
  description = "List of fargate profiles"
  value       = module.eks.fargate_profiles
}

output "issuer" {
  description = "EKS Identity issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

output "kubeconfig_file" {
  description = "Path of kubeconfig file"
  value       = local.kubeconfig_output_path
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.eks.node_security_group_id
}
