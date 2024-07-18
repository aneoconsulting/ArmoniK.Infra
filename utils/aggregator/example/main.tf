module "activemq" {
  source    = "../../../storage/onpremise/activemq"
  count     = 1
  namespace = "default"
  activemq = {
    image              = "symptoma/activemq"
    tag                = "5.18.3"
    node_selector      = {}
    image_pull_secrets = ""
  }
}

module "redis" {
  source    = "../../../storage/onpremise/redis"
  count     = 1
  namespace = "default"
  redis = {
    image              = "redis"
    tag                = "7.0.12-alpine3.18"
    node_selector      = {}
    image_pull_secrets = ""
    max_memory         = "8000gb"
    max_memory_samples = 8000
  }
}

module "control_plane" {
  source    = "../../aggregator"
  conf_list = concat(module.activemq, module.redis)

}

resource "kubernetes_deployment" "example" {
  metadata {
    name = "terraform-example"
    labels = {
      test = "MyExampleApp"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        test = "MyExampleApp"
      }
    }

    template {
      metadata {
        labels = {
          test = "MyExampleApp"
        }
      }

      spec {
        dynamic "volume" {
          for_each = keys(module.control_plane.mount_secret)
          content {

            name = module.control_plane.mount_secret[volume.value].secret
            secret {
              secret_name  = module.control_plane.mount_secret[volume.value].secret
              default_mode = module.control_plane.mount_secret[volume.value].mode

            }
          }
        }

        container {
          image = "nginx:1.21.6"
          name  = "example"

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
          dynamic "env" {
            for_each = module.control_plane.env
            content {
              name  = env.key
              value = env.value
            }
          }

          dynamic "env_from" {
            for_each = module.control_plane.env_secret
            content {
              secret_ref {
                name = env_from.value
              }
            }
          }

          dynamic "volume_mount" {
            for_each = keys(module.control_plane.mount_secret)
            content {
              mount_path = module.control_plane.mount_secret[volume_mount.value].path
              name       = module.control_plane.mount_secret[volume_mount.value].secret
              read_only  = true

            }

          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}
