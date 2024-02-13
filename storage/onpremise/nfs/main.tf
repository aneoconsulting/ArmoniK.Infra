resource "kubernetes_service_account" "nfs_client_provisioner" {
  metadata {
    name      = "nfs-client-provisioner"
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role" "nfs_client_provisioner_runner" {
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

resource "kubernetes_cluster_role_binding" "run_nfs_client_provisioner" {
  metadata {
    name = "run-nfs-client-provisioner"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.nfs_client_provisioner.metadata[0].name
    namespace = kubernetes_service_account.nfs_client_provisioner.metadata[0].namespace
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.nfs_client_provisioner_runner.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role" "leader_locking_nfs_client_provisioner" {
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

resource "kubernetes_role_binding" "leader_locking_nfs_client_provisioner" {
  metadata {
    name      = "leader-locking-nfs-client-provisioner"
    namespace = var.namespace
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.nfs_client_provisioner.metadata[0].name
    namespace = kubernetes_service_account.nfs_client_provisioner.metadata[0].namespace
  }

  role_ref {
    kind      = "Role"
    name      = kubernetes_role.leader_locking_nfs_client_provisioner.metadata[0].name
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

resource "kubernetes_deployment" "nfs_provisioner" {
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
        node_selector = var.node_selector
        dynamic "toleration" {
          for_each = var.node_selector
          content {
            key      = toleration.value
            operator = "Equal"
            value    = toleration.value
            effect   = "NoSchedule"
          }
        }
        dynamic "image_pull_secrets" {
          for_each = (var.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.image_pull_secrets
          }
        }
        service_account_name = "nfs-client-provisioner"
        container {
          name              = "nfs-provisioner"
          image             = "${var.image}:${var.tag}"
          image_pull_policy = var.image_policy

          # Mount NFS server details
          env {
            name  = "NFS_SERVER"
            value = var.server
          }
          env {
            name  = "NFS_PATH"
            value = var.path
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
            server = var.server
            path   = var.path
          }
        }
      }
    }
  }

}

# Persistent volume claim
resource "kubernetes_persistent_volume_claim" "nfs_claim" {
  metadata {
    name      = var.pvc_name
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    storage_class_name = "nfs-client"
  }
}
