# Kubeconfig rendered from the cluster attributes rather than written by gcloud: Terraform tracks the file, so a
# missing or edited file is rewritten on the next apply, a change of endpoint rewrites it and a destroy deletes it.
# It holds no credentials: kubectl gets a token through gke-gcloud-auth-plugin at each call. The file is replaced
# whole, never merged, so kubeconfig_path must be dedicated to this cluster.
locals {
  kubeconfig_context = "gke_${local.project}_${google_container_cluster.cluster.location}_${google_container_cluster.cluster.name}"
  # The DNS endpoint when it is the only one reachable from outside the VPC, the private IP from inside it
  kubeconfig_dns = !var.control_plane.enable_ip_endpoint || (local.private_endpoint && var.control_plane.dns_allow_external_traffic)
  kubeconfig_cluster = local.kubeconfig_dns ? {
    # Publicly trusted certificate
    server = "https://${google_container_cluster.cluster.control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint}"
    } : {
    server                     = "https://${local.private_endpoint ? google_container_cluster.cluster.private_cluster_config[0].private_endpoint : google_container_cluster.cluster.endpoint}"
    certificate-authority-data = google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  }
}

resource "local_sensitive_file" "kubeconfig" {
  count           = can(coalesce(var.kubeconfig_path)) ? 1 : 0
  filename        = abspath(var.kubeconfig_path)
  file_permission = "0600"
  content = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = local.kubeconfig_context
    clusters = [{
      name    = local.kubeconfig_context
      cluster = local.kubeconfig_cluster
    }]
    contexts = [{
      name = local.kubeconfig_context
      context = {
        cluster = local.kubeconfig_context
        user    = local.kubeconfig_context
      }
    }]
    users = [{
      name = local.kubeconfig_context
      user = {
        exec = {
          apiVersion         = "client.authentication.k8s.io/v1beta1"
          command            = "gke-gcloud-auth-plugin"
          installHint        = "Install gke-gcloud-auth-plugin: https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#install_plugin"
          provideClusterInfo = true
        }
      }
    }]
  })
}
