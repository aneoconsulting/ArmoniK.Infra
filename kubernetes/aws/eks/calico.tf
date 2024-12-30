resource "helm_release" "calico" {
  count      = local.enable_calico ? 1 : 0
  name       = "calico"
  namespace  = var.chart_namespace
  chart      = var.calico_chart_name
  version    = var.calico_chart_version
  repository = var.calico_chart_repository
  values = [
    yamlencode(local.node_selector),
    yamlencode({
      installation = {
        imagePullSecrets = var.calico_image_pull_secrets
      }
      tigeraOperator = {
        image    = "${var.calico_operator_image_name}"
        registry = ""
      }
      calicoctl = {
        image = "${var.calico_controller_image_name}:${var.calico_controller_image_tag}"
      }
    })
  ]
  depends_on = [
    null_resource.update_kubeconfig
  ]
}

resource "time_sleep" "wait_calico" {
  count = length(helm_release.calico)

  create_duration = "2s"

  depends_on = [helm_release.calico]
}

resource "kubectl_manifest" "calico_installation" {
  yaml_body = yamlencode({
    apiVersion = "operator.tigera.io/v1"
    kind       = "Installation"
    metadata = {
      name = "default"
    }
    spec = {
      controlPlaneNodeSelector = local.node_selector.nodeSelector
      controlPlaneTolerations  = local.tolerations.tolerations
      calicoNetwork = {
        bgp       = "Disabled"
        hostPorts = "Enabled"
        ipPools = [
          {
            allowedUses      = ["Workload", "Tunnel"]
            blockSize        = 26
            cidr             = "172.16.0.0/16"
            disableBGPExport = false
            encapsulation    = "VXLAN"
            name             = "default-ipv4-ippool"
            natOutgoing      = "Enabled"
            nodeSelector     = "all()"
          }
        ]
        linuxDataplane                 = "Iptables"
        linuxPolicySetupTimeoutSeconds = 0
        multiInterfaceMode             = "None"
        nodeAddressAutodetectionV4 = {
          canReach = "8.8.8.8"
        }
        windowsDataplane = "Disabled"
      }
      cni = {
        ipam = {
          type = "Calico"
        }
        type = "Calico"
      }
      controlPlaneReplicas    = 2
      flexVolumePath          = "/usr/libexec/kubernetes/kubelet-plugins/volume/exec/"
      imagePullSecrets        = var.calico_image_pull_secrets
      kubeletVolumePluginPath = "/var/lib/kubelet"
      kubernetesProvider      = "EKS"
      logging = {
        cni = {
          logFileMaxAgeDays = 30
          logFileMaxCount   = 10
          logFileMaxSize    = "100Mi"
          logSeverity       = "Info"
        }
      }
      nodeUpdateStrategy = {
        rollingUpdate = {
          maxUnavailable = 1
        }
        type = "RollingUpdate"
      }
      nonPrivileged = "Disabled"
      variant       = "Calico"
    }
  })

  depends_on = [time_sleep.wait_calico]
}

resource "null_resource" "remove_aws_node" {
  count = local.enable_calico ? 1 : 0
  provisioner "local-exec" {
    command = "kubectl delete daemonset aws-node -n kube-system"
    environment = {
      KUBECONFIG = local.kubeconfig_output_path
    }
  }
  depends_on = [
    null_resource.update_kubeconfig
  ]
}
