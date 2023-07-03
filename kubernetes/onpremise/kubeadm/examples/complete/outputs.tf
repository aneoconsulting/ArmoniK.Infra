output "kubeconfig_file" {
  description = "Use this export to begin to use your cluster"
  value       = "export KUBECONFIG=$HOME/.kube/config_remote"
}

output "kubeconfig_file" {
  description = "A sample command to display nodes of your cluster"
  value       = "kubectl --kubeconfig $HOME/.kube/config_remote get nodes"
}

