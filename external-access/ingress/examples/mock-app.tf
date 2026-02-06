resource "kubernetes_deployment" "test" {
  metadata {
    name = "test-app"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "test-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "test-app"
        }
      }
      spec {
        container {
          name  = "app"
          image = "python:3.11-alpine"
          command = [
            "python",
            "-m",
            "http.server",
            "8080"
          ]
          port {
            container_port = 8080
          }
          working_dir = "/app"
          env {
            name  = "PYTHONUNBUFFERED"
            value = "1"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "test" {
  metadata {
    name = "test-app-service"
  }
  spec {
    selector = {
      app = "test-app"
    }
    port {
      port        = 8080
      target_port = 8080
    }
    type = "ClusterIP"
  }
}
