output "kubeconfig_file_export_help" {
  description = "Use this export to begin to use your cluster"
  value       = "export KUBECONFIG=$HOME/.kube/config_remote"
}

output "display_nodes_command_help" {
  description = "A sample command to display nodes of your cluster"
  value       = "kubectl --kubeconfig $HOME/.kube/config_remote get nodes"
}

