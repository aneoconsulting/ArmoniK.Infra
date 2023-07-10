module "activemq" {
  source                           = "../../../activemq"
  namespace                        = kubernetes_namespace.armonik.metadata[0].name
  name                             = var.name
  image                            = var.image
  tag                              = var.tag
  node_selector                    = var.node_selector
  image_pull_secrets               = var.image_pull_secrets
  security_context                 = var.security_context
  min_ready_seconds                = var.min_ready_seconds
  progress_deadline_seconds        = var.progress_deadline_seconds
  revision_history_limit           = var.revision_history_limit
  termination_grace_period_seconds = var.termination_grace_period_seconds
  strategy_update                  = var.strategy_update
  restart_policy                   = var.restart_policy
  rolling_update                   = var.rolling_update
  priority_class_name              = var.priority_class_name
  node_name                        = var.node_name
  active_deadline_seconds          = var.active_deadline_seconds
  toleration                       = var.toleration

}
resource "kubernetes_namespace" "armonik" {
  metadata {
    name = var.namespace
  }
}
