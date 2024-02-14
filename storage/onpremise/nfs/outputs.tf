# nfs

output "provisioner_name" {
  description = "name of the created provisionner"
  value       = kubernetes_deployment.nfs_provisioner.metadata[0].name
}


output "pvc_name" {
  description = "name of the created persistant volume claim"
  value       = kubernetes_persistent_volume_claim.nfs_claim.metadata[0].name
}
