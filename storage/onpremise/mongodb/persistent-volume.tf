resource "kubernetes_storage_class" "mongodb" {
  # enable if var.persistent_volume is not null and var.persistent_volume.storage_provisioner is neither null nor empty
  count = can(coalesce(var.persistent_volume.storage_provisioner)) ? 1 : 0
  metadata {
    name = "mongodb"
    labels = {
      app     = "mongodb"
      type    = "storage-class"
      service = "persistent-volume"
    }
  }
  mount_options       = var.persistent_volume.storage_provisioner == "ebs.csi.aws.com" ? null : ["tls"]
  storage_provisioner = var.persistent_volume.storage_provisioner
  reclaim_policy      = var.persistent_volume.reclaim_policy
  volume_binding_mode = var.persistent_volume.volume_binding_mode
  parameters          = var.persistent_volume.parameters
}
