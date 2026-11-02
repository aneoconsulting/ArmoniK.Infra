# gcloud writes the credentials of the cluster to the file once created.
# Proposal to discuss: a local_sensitive_file rendered from the cluster outputs (endpoint, CA, exec through
# gke-gcloud-auth-plugin) instead. No gcloud call at apply time, no merge into an existing file, the file follows the
# cluster (deleted on destroy, rewritten when the endpoint changes), at the cost of the hashicorp/local provider.
resource "terraform_data" "kubeconfig" {
  count = can(coalesce(var.kubeconfig_path)) ? 1 : 0
  triggers_replace = [
    abspath(var.kubeconfig_path),
    google_container_cluster.cluster.id,
  ]
  provisioner "local-exec" {
    # The DNS endpoint when it is the only one reachable from outside the VPC, the private one from inside it
    command = join(" ", compact([
      "gcloud container clusters get-credentials ${google_container_cluster.cluster.name}",
      "--location=${google_container_cluster.cluster.location}",
      "--project=${local.project}",
      !var.control_plane.enable_ip_endpoint || (local.private_endpoint && var.control_plane.dns_allow_external_traffic) ? "--dns-endpoint" : (local.private_endpoint ? "--internal-ip" : ""),
    ]))
    environment = {
      KUBECONFIG = abspath(var.kubeconfig_path)
    }
  }
}
