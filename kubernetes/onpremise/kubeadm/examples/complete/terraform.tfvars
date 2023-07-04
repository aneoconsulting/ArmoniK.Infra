master = {
  name                     = "master-1"
  public_dns               = "PUBLIC_DNS_HERE" # it can be private if you are in the dest network
  private_dns              = "PRIVATE_DNS_HERE"
  tls_private_key_pem_file = "TLS_PRIVATE_KEY_FILE_HERE"
}

workers = {
  "worker-1" = {
    "name"       = "worker-1"
    "labels"     = ["workers"]
    "taints"     = ["workers"]
    "public_dns" = "PUBLIC_DNS_HERE" # it can be private if you are in the dest network
  },
  "worker-2" = {
    "name"       = "worker-2"
    "labels"     = ["workers"]
    "taints"     = ["workers"]
    "public_dns" = "PUBLIC_DNS_HERE" # it can be private if you are in the dest network
  }
}

user = "ec2-user" #ec2-user is used for redhat image by default
