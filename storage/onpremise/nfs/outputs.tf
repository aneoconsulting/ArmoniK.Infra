# nfs

output "provisioner_name" {
  value = kubernetes_deployment.nfs_provisioner.metadata[0].name
}


output "pvc_name" {
  value = kubernetes_persistent_volume_claim.nfs_claim.metadata[0].name
}
