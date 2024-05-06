# nfs

output "provisioner_name" {
  description = "name of the created provisionner"
  value       = kubernetes_deployment.nfs_provisioner.metadata[0].name
}


output "pvc_name" {
  description = "name of the created persistant volume claim"
  value       = kubernetes_persistent_volume_claim.nfs_claim.metadata[0].name
}

#new outputs
output "env" {
  description = "Elements to be set as environment variables"
  value = ({
    "Components__ObjectStorage" = var.object_storage_adapter
    "LocalStorage__Path"        = var.mount_path
  })
}

output "mount_volume" {
  description = "Volume to be mounted"
  value = {
    "volume1" = {
      path       = var.mount_path
      claim_name = var.pvc_name
    }
  }
}
