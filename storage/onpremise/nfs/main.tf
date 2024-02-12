resource "kubernetes_service_account" "nfs-client-provisioner" {
  metadata {
    name      = "nfs-client-provisioner"
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role" "nfs-client-provisioner-runner" {
  metadata {
    name = "nfs-client-provisioner-runner"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get", "list", "watch", "create", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "update"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "update", "patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
}

resource "kubernetes_cluster_role_binding" "run-nfs-client-provisioner" {
  metadata {
    name = "run-nfs-client-provisioner"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.nfs-client-provisioner.metadata[0].name
    namespace = kubernetes_service_account.nfs-client-provisioner.metadata[0].namespace
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.nfs-client-provisioner-runner.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role" "leader-locking-nfs-client-provisioner" {
  metadata {
    name      = "leader-locking-nfs-client-provisioner"
    namespace = var.namespace
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
}

resource "kubernetes_role_binding" "leader-locking-nfs-client-provisioner" {
  metadata {
    name      = "leader-locking-nfs-client-provisioner"
    namespace = var.namespace
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.nfs-client-provisioner.metadata[0].name
    namespace = kubernetes_service_account.nfs-client-provisioner.metadata[0].namespace
  }

  role_ref {
    kind      = "Role"
    name      = kubernetes_role.leader-locking-nfs-client-provisioner.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}


# Kubernetes nfs deployment
resource "kubernetes_storage_class" "nfs_client" {
  metadata {
    name = "nfs-client"
  }

  storage_provisioner    = "nfs-provisioner"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true
  mount_options          = []

  parameters = {
    archiveOnDelete = true
  }


}

resource "kubernetes_deployment" "nfs-provisioner" {
  metadata {
    name      = "nfs-provisioner"
    namespace = var.namespace
    labels = {
      app     = "storage"
      type    = "object"
      service = "nfs"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = "storage"
        type    = "object"
        service = "nfs"
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        name = "nfs-provisioner"
        labels = {
          app     = "storage"
          type    = "object"
          service = "nfs"
        }
      }
      spec {
        node_selector = var.nfs_client.node_selector
        dynamic "toleration" {
          for_each = (var.nfs_client.node_selector != {} ? [
            for index in range(0, length(local.node_selector_keys)) : {
              key   = local.node_selector_keys[index]
              value = local.node_selector_values[index]
            }
          ] : [])
          content {
            key      = toleration.value.key
            operator = "Equal"
            value    = toleration.value.value
            effect   = "NoSchedule"
          }
        }
        dynamic "image_pull_secrets" {
          for_each = (var.nfs_client.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.nfs_client.image_pull_secrets
          }
        }
        service_account_name = "nfs-client-provisioner"
        container {
          name              = "nfs-provisioner"
          image             = "${var.nfs_client.image}:${var.nfs_client.tag}"
          image_pull_policy = "IfNotPresent"

          # Mount NFS server details
          env {
            name  = "NFS_SERVER"
            value = var.nfs_server
          }
          env {
            name  = "NFS_PATH"
            value = var.nfs_path
          }

          volume_mount {
            name       = "nfs-client-root"
            mount_path = "/persistentvolumes"
          }
          # StorageClass configuration
          env {
            name  = "STORAGE_CLASS"
            value = "nfs-client"
          }
          env {
            name  = "RECLAIM_POLICY"
            value = "Delete"
          }
          env {
            name  = "ARCHIVE_ON_DELETE"
            value = "true"
          }
          env {
            name  = "ACCESS_MODES"
            value = "ReadWriteOnce"
          }
          env {
            name  = "VOLUME_BINDING_MODE"
            value = "Immediate"
          }
          env {
            name  = "ALLOW_VOLUME_EXPANSION"
            value = "true"
          }
          env {
            name  = "PROVISIONER_NAME"
            value = "nfs-provisioner"
          }

          # Leader election configuration
          env {
            name  = "LEADER_ELECTION"
            value = "true"
          }

          # RBAC configuration
          env {
            name  = "RBAC_ENABLED"
            value = "true"
          }

          # Pod Security Policy configuration
          env {
            name  = "POD_SECURITY_POLICY_ENABLED"
            value = "false"
          }

          # Service Account configuration
          env {
            name  = "SERVICE_ACCOUNT_CREATE"
            value = "true"
          }
          env {
            name  = "SERVICE_ACCOUNT_ANNOTATIONS"
            value = "{}"
          }
        }
        volume {
          name = "nfs-client-root"
          nfs {
            server = var.nfs_server
            path   = var.nfs_path
          }
        }
      }
    }
  }

}

# Persistent volume claim
resource "kubernetes_persistent_volume_claim" "nfs_claim" {
  # count = var.nfs != null ? 1 : 0
  metadata {
    name      = var.pvc_name #"nfsvolume"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    #volume_name = "${kubernetes_persistent_volume.nfs_pv.metadata.0.name}"
    storage_class_name = "nfs-client"
  }
}