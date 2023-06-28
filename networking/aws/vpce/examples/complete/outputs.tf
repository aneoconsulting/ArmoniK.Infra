output "vpc_id" {
  description = "The ID of the VPC in which are created the VPC endpoints."
  value       = module.vpc.id
}

output "endpoints" {
  description = "Array containing the full resource object and attributes for all endpoints created"
  value       = module.vpce.endpoints
}
