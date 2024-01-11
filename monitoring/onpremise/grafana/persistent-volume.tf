resource "kubernetes_storage_class" "grafana" {
  count = can(coalesce(var.persistent_volume)) ? 1 : 0
  metadata {
    name = "grafana"
    labels = {
      app     = "grafana"
      type    = "storage-class"
      service = "persistent-volume"
    }
  }
  mount_options       = ["tls"]
  storage_provisioner = var.persistent_volume.storage_provisioner
  volume_binding_mode = var.persistent_volume.volume_binding_mode
  parameters          = var.persistent_volume.parameters
}

resource "kubernetes_persistent_volume_claim" "grafana" {
  count = length(kubernetes_storage_class.grafana) > 0 ? 1 : 0
  metadata {
    name      = "grafana"
    namespace = var.namespace
    labels = {
      app     = "grafana"
      type    = "persistent-volume-claim"
      service = "persistent-volume"
    }
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.grafana[0].metadata[0].name
    resources {
      requests = var.persistent_volume.resources.requests
      limits   = var.persistent_volume.resources.limits
    }
  }
}
