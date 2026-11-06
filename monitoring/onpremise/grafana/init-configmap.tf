resource "kubernetes_config_map" "grafana_ini" {
  metadata {
    name      = "grafana-ini-configmap"
    namespace = var.namespace
  }
  # root_url stays path-less: the ArmoniK ingress serves Grafana under /<cluster>/grafana/, strips that prefix and
  # injects it as Grafana's appSubUrl, which Grafana uses for the URLs it builds itself (preloaded app plugins, ...).
  data = {
    "grafana.ini" = <<-EOF
    [server]
    domain=localhost
    root_url = %(protocol)s://%(domain)s:%(http_port)s/
    serve_from_sub_path = false
    %{if !var.authentication}
    [auth.anonymous]
    enabled = true
    %{endif}
    EOF
  }
}
