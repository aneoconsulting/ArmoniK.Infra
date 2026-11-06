# SeaweedFS in all-in-one mode: master, volume, filer and S3 gateway in a single pod
resource "helm_release" "seaweedfs" {
  name       = var.name
  namespace  = var.namespace
  repository = var.helm_chart_repository
  chart      = var.helm_chart_name
  version    = var.helm_chart_version
  timeout    = var.timeout

  values = [
    yamlencode({
      fullnameOverride = var.name

      global = {
        imagePullSecrets = compact([var.image_pull_secrets])
        seaweedfs = {
          image = {
            name = var.image
          }
          # The chart always renders this ServiceAccount: one per release avoids a clash between two releases
          serviceAccountName = var.name
          # Only bound to that ServiceAccount, which the all-in-one pod does not use
          createClusterRole = false
        }
      }

      image = merge(
        { registry = var.registry },
        var.tag != null ? { tag = var.tag } : {},
      )

      # The distributed components are rendered independently of allInOne
      master = { enabled = false }
      volume = { enabled = false }
      filer  = { enabled = false }
      s3     = { enabled = false }

      allInOne = merge({
        enabled = true
        s3 = {
          enabled              = true
          enableAuth           = true
          existingConfigSecret = kubernetes_secret_v1.s3_config.metadata[0].name
          # post-install/post-upgrade hook Job
          createBuckets = [{ name = var.bucket_name }]
        }
        data = local.persistence
        # The chart renders these two through tpl: they are YAML strings
        nodeSelector = length(var.node_selector) > 0 ? yamlencode(var.node_selector) : ""
        tolerations  = length(local.tolerations) > 0 ? yamlencode(local.tolerations) : ""
      }, length(local.resources) > 0 ? { resources = local.resources } : {})
    })
  ]
}
