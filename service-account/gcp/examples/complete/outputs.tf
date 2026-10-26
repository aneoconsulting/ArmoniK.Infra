output "member" {
  description = "IAM member of the Kubernetes service account"
  value       = module.complete_service_account.member
}

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke.name
}

output "bucket_url" {
  description = "URL of the bucket the test pod can list"
  value       = module.bucket.url
}
