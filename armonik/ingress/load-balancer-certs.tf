resource "kubernetes_secret" "cluster_certs" {
  count = var.load_balancer != null ? 1 : 0
  metadata {
    name      = "${local.prefix}lb-cluster-certs"
    namespace = var.namespace
  }
  data = merge([
    for cluster, conf in var.clusters :
    {
      ("${cluster}.cert") = can(coalesce(conf.cert_pem)) ? file(conf.cert_pem) : null
      ("${cluster}.key")  = can(coalesce(conf.key_pem)) ? file(conf.key_pem) : null
      ("${cluster}.ca")   = can(coalesce(conf.ca_cert)) ? file(conf.ca_cert) : null
    }
  ]...)
}
