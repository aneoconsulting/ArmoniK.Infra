locals {
  tags                 = merge(var.tags, { module = "pv-efs" })
  efs_csi_name         = try(var.csi_driver_name, "efs-csi-driver")
  efs_csi_namespace    = try(var.csi_driver_namespace, "kube-system")
  oidc_arn             = var.oidc_arn
  oidc_url             = var.oidc_url
  node_selector_keys   = keys(var.csi_driver_node_selector)
  node_selector_values = values(var.csi_driver_node_selector)
  tolerations = [
    for index in range(0, length(local.node_selector_keys)) : {
      key      = local.node_selector_keys[index]
      operator = "Equal"
      value    = local.node_selector_values[index]
      effect   = "NoSchedule"
    }
  ]
  controller = {
    controller = {
      create                   = true
      logLevel                 = 2
      extraCreateMetadata      = true
      tags                     = {}
      deleteAccessPointRootDir = false
      volMetricsOptIn          = false
      podAnnotations           = {}
      resources                = {}
      nodeSelector             = var.csi_driver_node_selector
      tolerations              = local.tolerations
      affinity                 = {}
      serviceAccount = {
        create      = false
        name        = kubernetes_service_account.efs_csi_driver.metadata[0].name
        annotations = {}
      }
      healthPort           = 9909
      regionalStsEndpoints = false
    }
  }
}

resource "helm_release" "efs_csi" {
  name       = "efs-csi"
  namespace  = kubernetes_service_account.efs_csi_driver.metadata[0].namespace
  chart      = "aws-efs-csi-driver"
  repository = var.csi_driver_repository
  version    = var.csi_driver_version

  set {
    name  = "image.repository"
    value = var.efs_csi_image
  }
  set {
    name  = "image.tag"
    value = var.efs_csi_tag
  }
  set {
    name  = "imagePullSecrets"
    value = var.csi_driver_image_pull_secrets
  }
  set {
    name  = "sidecars.livenessProbe.image.repository"
    value = var.livenessprobe_image
  }
  set {
    name  = "sidecars.livenessProbe.image.tag"
    value = var.livenessprobe_tag
  }
  set {
    name  = "sidecars.nodeDriverRegistrar.image.repository"
    value = var.node_driver_registrar_image
  }
  set {
    name  = "sidecars.nodeDriverRegistrar.image.tag"
    value = var.node_driver_registrar_tag
  }
  set {
    name  = "sidecars.csiProvisioner.image.repository"
    value = var.external_provisioner_image
  }
  set {
    name  = "sidecars.csiProvisioner.image.tag"
    value = var.external_provisioner_tag
  }

  values = [
    yamlencode(local.controller)
  ]
}
