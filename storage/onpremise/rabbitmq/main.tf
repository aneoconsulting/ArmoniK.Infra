
resource "kubernetes_namespace" "rabbitmq" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "rabbitmq" {
  name       = "rabbitmq"
  namespace  = kubernetes_namespace.rabbitmq.metadata[0].name
  chart      = "rabbitmq"
  repository = var.helm_chart_repository
  version    = var.helm_chart_version

  set {
    name  = "image.rabbitmq.repository"
    value = var.docker_image.rabbitmq.image
  }

  set {
    name  = "image.rabbitmq.tag"
    value = var.docker_image.rabbitmq.tag
  }

  set {
    name  = "rabbitmq.service.type"
    value = var.service_type
  }

  set {
    name  = "defaultUsername"
    value = "admin"
  }

  set {
    name  = "defaultPassword"
    value = "admin"
  }

  # Parameter	Description	Default
  # image.rabbitmq.repository	The image of RabbitMQ container	rabbitmq
  # image.rabbitmq.tag	The tag of the RabbitMQ image	3.8.1-alpine
  # image.rabbitmq.pullPolicy	The pull policy of the RabbitMQ image	IfNotPresent
  # extraPlugins	Extra plugins enabled	[]
  # extraConfigurations	Extra configurations to append to rabbitmq.conf	``
  # advancedConfigurations	advanced.config	``
  # defaultUsername	The username of default user to interact with RabbitMQ	admin
  # defaultPassword	The password of default user to interact with RabbitMQ	password
  # service.type	The service type, can be ClusterIP, or NodePort	ClusterIP

}



