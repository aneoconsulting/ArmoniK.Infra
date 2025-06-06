# configmap with all the variables
resource "kubernetes_config_map" "fluent_bit_config_windows" {
  count = (length(var.node_selector_windows) > 0 ? 1 : 0)
  metadata {
    name      = "fluent-bit-configmap-windows"
    namespace = var.namespace
    labels = {
      app                             = "armonik"
      type                            = "logs"
      service                         = "fluent-bit"
      version                         = "v1"
      "kubernetes.io/cluster-service" = "true"
    }
  }
  data = {
    "fluent-bit.conf"        = file("${path.module}/configs/service/fluent-bit.conf")
    "input-kubernetes.conf"  = (local.fluent_bit_windows_is_daemonset ? file("${path.module}/configs/input/input-kubernetes-daemonset.conf") : file("${path.module}/configs/input/input-kubernetes-sidecar.conf"))
    "filter-kubernetes.conf" = (local.fluent_bit_windows_is_daemonset ? file("${path.module}/configs/filter/filter-kubernetes-daemonset.conf") : file("${path.module}/configs/filter/filter-kubernetes-sidecar.conf"))
    "output-http-seq.conf"   = (local.seq_enabled ? file("${path.module}/configs/output/output-http-seq.conf") : file("${path.module}/configs/output/output-empty.conf"))
    "output-cloudwatch.conf" = (local.cloudwatch_enabled ? file("${path.module}/configs/output/output-cloudwatch.conf") : file("${path.module}/configs/output/output-empty.conf"))
    "output-s3.conf"         = (local.s3_enabled ? file("${path.module}/configs/output/output-s3.conf") : file("${path.module}/configs/output/output-empty.conf"))
    "output-stdout.conf"     = (!local.seq_enabled && !local.cloudwatch_enabled ? file("${path.module}/configs/output/output-stdout.conf") : file("${path.module}/configs/output/output-empty.conf"))
    "parsers.conf"           = file("${path.module}/configs/parser/parsers.conf")
  }
}
