resource "kubernetes_namespace_v1" "armonik" {
  metadata {
    name = "armonik"
  }
}

module "armonik" {
  source        = "../.."
  namespace     = kubernetes_namespace_v1.armonik.metadata[0].name
  chart_version = "0.17.1"
  partitions = {
    bench = {
      image = "docker.io/dockerhubaneo/armonik_core_bench_test_worker"
      tag   = "0.41.4"
    }
  }
}
