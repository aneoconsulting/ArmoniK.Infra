resource "helm_release" "eni_config" {
  name       = "add-subnet"
  chart      = var.chart_name
  version    = var.chart_version
  namespace  = var.chart_namespace
  repository = "${path.module}/${var.chart_repository}"
  values     = [yamlencode(local.subnets)]
  depends_on = [
    null_resource.update_kubeconfig
  ]
}

resource "null_resource" "change_cni_label" {
  provisioner "local-exec" {
    command = "kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=topology.kubernetes.io/zone"
    environment = {
      KUBECONFIG = local.kubeconfig_output_path
    }
  }
  depends_on = [
    null_resource.update_kubeconfig
  ]
}
