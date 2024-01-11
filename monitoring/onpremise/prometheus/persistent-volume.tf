resource "kubernetes_storage_class" "prometheus" {
  count = can(coalesce(var.persistent_volume)) ? 1 : 0
  metadata {
    name = "prometheus"
    labels = {
      app     = "prometheus"
      type    = "storage-class"
      service = "persistent-volume"
    }
  }
  mount_options       = ["tls"]
  storage_provisioner = var.persistent_volume.storage_provisioner
  volume_binding_mode = var.persistent_volume.volume_binding_mode
  parameters          = var.persistent_volume.parameters
}

resource "kubernetes_persistent_volume_claim" "prometheus" {
  count = length(kubernetes_storage_class.prometheus) > 0 ? 1 : 0
  metadata {
    name      = "prometheus"
    namespace = var.namespace
    labels = {
      app     = "prometheus"
      type    = "persistent-volume-claim"
      service = "persistent-volume"
    }
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.prometheus[0].metadata[0].name
    resources {
      requests = var.persistent_volume.resources.requests
      limits   = var.persistent_volume.resources.limits
    }
  }
}
