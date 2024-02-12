# nfs

output "provisioner_name" {
  value = kubernetes_deployment.nfs-provisioner.metadata.0.name
}