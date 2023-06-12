# Needed resource for each storage
output "needed_storage" {
  description = "List of storage required by ArmoniK"
  value       = local.needed_storage
}

# List of resources to deploy
output "list_storage" {
  description = "List of deployed storage"
  value       = local.list_storage
}
