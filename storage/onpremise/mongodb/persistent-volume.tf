/*resource "kubernetes_storage_class" "mongodb" {
  count = var.persistent_volume != null ? 1 : 0
  metadata {
    name = "mongodb"
    labels = {
      app     = "mongodb"
      type    = "storage-class"
      service = "persistent-volume"
    }
  }
  mount_options       = ["tls"]
  storage_provisioner = var.persistent_volume.storage_provisioner
  volume_binding_mode = var.persistent_volume.volume_binding_mode
  parameters          = var.persistent_volume.parameters
}

resource "kubernetes_persistent_volume_claim" "mongodb" {
  count = length(kubernetes_storage_class.mongodb) > 0 ? 1 : 0
  metadata {
    name      = "mongodb"
    namespace = var.namespace
    labels = {
      app     = "mongodb"
      type    = "persistent-volume-claim"
      service = "persistent-volume"
    }
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.mongodb[0].metadata[0].name
    resources {
      requests = var.persistent_volume.resources.requests
      limits   = var.persistent_volume.resources.limits
    }
  }
}
*/

resource "kubernetes_persistent_volume" "mongodb" {
  count = var.persistent_volume != null ? 1 : 0
  metadata {
    name = "mongodb"
    labels = {
      app     = "mongodb"
      type    = "storage-class"
      service = "persistent-volume"
    }
  }
  spec {
    access_modes = ["ReadWriteMany"]
    capacity     = {
      storage = var.persistent_volume.resources.requests["storage"]
    }
    volume_mode = "Filesystem"
    storage_class_name = ""
    persistent_volume_reclaim_policy = "Delete"
    persistent_volume_source {
      csi {
        driver        = "efs.csi.aws.com"
        volume_handle = var.persistent_volume.parameters.fileSystemId
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "mongodb" {
  count = var.persistent_volume != null ? 1 : 0
  metadata {
    name      = "mongodb"
    namespace = var.namespace
    labels = {
      app     = "mongodb"
      type    = "persistent-volume-claim"
      service = "persistent-volume"
    }
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = ""
    resources {
      requests = var.persistent_volume.resources.requests
      limits   = var.persistent_volume.resources.limits
    }
  }
}
