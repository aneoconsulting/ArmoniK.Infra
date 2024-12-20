# Define the YAML configuration as a file current version of kubernetes provider doesn't support windowsOptions; and there is a bug in the provider with the option: https://github.com/hashicorp/terraform-provider-kubernetes/issues/2575

resource "kubectl_manifest" "windows_exporter" {
  yaml_body = yamlencode({
    apiVersion = "apps/v1"
    kind       = "DaemonSet"
    metadata = {
      name      = var.name
      namespace = var.namespace
      labels = {
        app     = "armonik"
        type    = "monitoring"
        service = "windows-exporter"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app     = "armonik"
          type    = "monitoring"
          service = "windows-exporter"
        }
      }
      template = {
        metadata = {
          labels = {
            app     = "armonik"
            type    = "monitoring"
            service = "windows-exporter"
          }
          annotations = {
            "prometheus.io/scrape" = "true"
            "prometheus.io/scheme" = "http"
            "prometheus.io/path"   = "/metrics"
            "prometheus.io/port"   = "9182"
            "prometheus.io/input"  = "windows-exporter"
          }
        }
        spec = {
          securityContext = {
            windowsOptions = {
              hostProcess   = true
              runAsUserName = "NT AUTHORITY\\system"
            }
          }
          hostNetwork = true
          initContainers = [
            {
              name    = "configure-firewall"
              image   = "${var.init_docker_image.image}:${var.init_docker_image.tag}"
              command = ["powershell"]
              args    = ["New-NetFirewallRule", "-DisplayName", "'windows-exporter'", "-Direction", "inbound", "-Profile", "Any", "-Action", "Allow", "-LocalPort", "9182", "-Protocol", "TCP"]
            }
          ]
          containers = [
            {
              name  = "windows-exporter"
              image = "${var.docker_image.image}:${var.docker_image.tag}"
              args  = ["--config.file=%CONTAINER_SANDBOX_MOUNT_POINT%/config.yml"]
              ports = [
                {
                  containerPort = 9182
                  hostPort      = 9182
                  name          = "http"
                }
              ]
              volumeMounts = [
                {
                  name      = "windows-exporter-config"
                  mountPath = "/config.yml"
                  subPath   = "config.yml"
                }
              ]
            }
          ]
          nodeSelector = merge(
            {
              "kubernetes.io/os"   = "windows"
              "kubernetes.io/arch" = "amd64"
            },
            var.node_selector
          )
          tolerations = concat(
            [
              {
                key      = "kubernetes.io/arch"
                operator = "Equal"
                value    = "amd64"
                effect   = "NoSchedule"
              },
              {
                key      = "kubernetes.io/os"
                operator = "Equal"
                value    = "windows"
                effect   = "NoSchedule"
              }
            ],
            [
              for key, value in var.node_selector : {
                key      = key
                operator = "Equal"
                value    = value
                effect   = "NoSchedule"
              }
            ]
          )
          volumes = [
            {
              name = "windows-exporter-config"
              configMap = {
                name = "windows-exporter-config"
              }
            }
          ]
        }
      }
    }
  })
}

# windows-exporter config map
resource "kubernetes_config_map" "windows_exporter_config" {
  metadata {
    name      = "windows-exporter-config"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      type    = "monitoring"
      service = "windows-exporter"
    }
  }

  data = {
    "config.yml" = yamlencode({
      collectors = {
        enabled = "cpu_info,container,logical_disk,memory,net,os"
      }
      collector = {
        service = {
          services-where = "Name='containerd' or Name='kubelet'"
        }
      }
    })
  }
}

# windows-exporter service
resource "kubernetes_service" "windows_exporter" {
  metadata {
    name      = "windows-exporter"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      type    = "monitoring"
      service = "windows-exporter"
    }
  }

  spec {
    selector = {
      app     = "armonik"
      type    = "monitoring"
      service = "windows-exporter"
    }

    port {
      name        = "http"
      protocol    = "TCP"
      port        = 9182
      target_port = 9182
    }
  }
}
