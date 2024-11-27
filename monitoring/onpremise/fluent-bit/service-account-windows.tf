# Service account and role for Fluent-bit
# For Kubernetes 1.23 and later, otherwise use kubernetes_manifest
resource "kubernetes_service_account" "fluent_bit_windows" {
  count = (local.fluent_bit_windows_is_daemonset ? 1 : 0)
  metadata {
    name      = "fluent-bit-windows"
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role" "fluent_bit_role_windows" {
  count = (local.fluent_bit_windows_is_daemonset ? 1 : 0)
  metadata {
    name = "fluent-bit-role-windows"
  }
  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }
  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods", "pods/logs", "nodes", "nodes/proxy"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "fluent_bit_role_binding_windows" {
  count = (local.fluent_bit_windows_is_daemonset ? 1 : 0)
  metadata {
    name = "fluent-bit-role-binding-windows"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.fluent_bit_role_windows[0].metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.fluent_bit_windows[0].metadata[0].name
    namespace = kubernetes_service_account.fluent_bit_windows[0].metadata[0].namespace
  }
}
