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

#update the config map for windows to be able to give IP to pods
resource "kubernetes_config_map_v1_data" "amazon_vpc_cni" {
  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }
  force = true
  data = {
    enable-windows-ipam = "true"
    enable-windows-prefix-delegation : "true"
  }
  depends_on = [
    module.eks,
    null_resource.update_kubeconfig
  ]
}
