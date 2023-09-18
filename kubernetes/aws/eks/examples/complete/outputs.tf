# EKS
output "cluster_name" {
  description = "Name of the cluster"
  value       = module.eks.cluster_name
}

output "cluster_id" {
  description = "Id of the cluster"
  value       = module.eks.cluster_id
}

output "managed_worker_iam_role_names" {
  description = "EKS managed worker iam role names"
  value       = module.eks.eks_managed_worker_iam_role_names
}

output "self_managed_worker_iam_role_names" {
  description = "EKS self managed worker iam role names"
  value       = module.eks.self_managed_worker_iam_role_names
}

output "fargate_profiles_worker_iam_role_names" {
  description = "List of fargate profiles"
  value       = module.eks.fargate_profiles_worker_iam_role_names
}

output "worker_iam_role_names" {
  description = "list of the workers IAM role names"
  value       = module.eks.worker_iam_role_names
}

output "issuer" {
  description = "EKS Identity issuer"
  value       = module.eks.issuer
}

output "kubeconfig" {
  description = "Use multiple Kubernetes cluster with KUBECONFIG environment variable"
  value       = "export KUBECONFIG=${module.eks.kubeconfig_file}"
}
