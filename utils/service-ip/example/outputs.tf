output "ip" {
  description = "IP of the service deployed"
  value       = module.my_svc_ip.ip
}

output "domain" {
  description = "Domain of the service deployed"
  value       = module.my_svc_ip.domain
}

output "fqdn" {
  description = "Fully Qualified Domain Name of the service deployed"
  value       = module.my_svc_ip.fqdn
}

output "host" {
  description = "Either the IP of the FQDN or the deployed service"
  value       = module.my_svc_ip.host
}

output "port" {
  description = "Port used by the service deployed"
  value       = module.my_svc_ip.ports[0]
}
