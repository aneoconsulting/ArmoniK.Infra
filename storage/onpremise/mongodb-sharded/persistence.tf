resource "kubernetes_storage_class" "shards" {
  # enable if var.persistence.shards is not null and var.persistence.shards.storage_provisioner is neither null nor empty
  count = can(coalesce(var.persistence.shards.storage_provisioner)) ? 1 : 0
  metadata {
    name = "${var.name}-shards"
    labels = {
      app     = "mongodb"
      type    = "storage-class"
      service = "persistent-volume"
    }
  }
  mount_options       = var.persistence.shards.storage_provisioner == "ebs.csi.aws.com" ? null : ["tls"]
  storage_provisioner = var.persistence.shards.storage_provisioner
  reclaim_policy      = var.persistence.shards.reclaim_policy
  volume_binding_mode = var.persistence.shards.volume_binding_mode
  parameters          = var.persistence.shards.parameters
}

resource "kubernetes_storage_class" "configsvr" {
  # enable if var.persistence.configsvr.storage_provisioner is neither null nor empty
  count = can(coalesce(var.persistence.configsvr.storage_provisioner)) ? 1 : 0
  metadata {
    name = "${var.name}-configsvr"
    labels = {
      app     = "mongodb"
      type    = "storage-class"
      service = "persistent-volume"
    }
  }
  mount_options       = var.persistence.configsvr.storage_provisioner == "ebs.csi.aws.com" ? null : ["tls"]
  storage_provisioner = var.persistence.configsvr.storage_provisioner
  reclaim_policy      = var.persistence.configsvr.reclaim_policy
  volume_binding_mode = var.persistence.configsvr.volume_binding_mode
  parameters          = var.persistence.configsvr.parameters
}
