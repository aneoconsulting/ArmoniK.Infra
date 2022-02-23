output "arn" {
  description = "ARN of EKS cluster"
  value       = data.aws_eks_cluster.cluster.arn
}
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "certificate_authority" {
  description = "Endpoint for EKS control plane"
  value       = data.aws_eks_cluster.cluster.certificate_authority
}

output "token" {
  description = "Authentication token for EKS"
  value       = data.aws_eks_cluster_auth.cluster.token
  sensitive   = true
}

output "name" {
  description = "Name of EKS cluster"
  value       = module.eks.cluster_id
}

output "kms_key_id" {
  description = "ARN of KMS used for EKS"
  value       = {
    cluster_log_kms_key_id    = var.eks.encryption_keys.cluster_log_kms_key_id
    cluster_encryption_config = var.eks.encryption_keys.cluster_encryption_config
    ebs_kms_key_id            = var.eks.encryption_keys.ebs_kms_key_id
  }
}

output "worker_iam_role_name" {
  description = "EKS worker IAM role name"
  value = module.eks.worker_iam_role_name
}

output "cluster_id" {
  description = "EKS cluster ID"
  value = module.eks.cluster_id
}
