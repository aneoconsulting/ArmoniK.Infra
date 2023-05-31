output "workers" {
  value = module.workers
}

output "master" {
  value = module.master
}

output "ssh-key" {
  value = tls_private_key.ssh-key
}