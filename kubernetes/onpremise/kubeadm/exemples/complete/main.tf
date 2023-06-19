
locals {
  master = {
    name                = "master-1"
    public_dns          = "ec2-3-8-5-81.master.eu-west-2.compute.amazonaws.com"
    private_dns         = "10.0.0.1"
    tls_private_key_pem = "my master node ssh private key"
  }
  workers = {
    "worker-1" = {
      "name"                = "worker-1"
      "labels"              = tolist(["workers", ])
      "taints"              = tolist(["workers", ])
      "public_dns"          = "ec2-3-8-5-81.worker-1.eu-west-2.compute.amazonaws.com"
      "tls_private_key_pem" = "my worker-1 node ssh private key"
    },
    "worker-2" = {
      "name"                = "worker-2"
      "labels"              = tolist(["workers", ])
      "taints"              = tolist(["workers", ])
      "public_dns"          = "ec2-3-8-5-82..worker-2.eu-west-2.compute.amazonaws.com"
      "tls_private_key_pem" = "my worker-2 node ssh private key"
    }
  }
  user  = "ec2-user" #default redhat user
  token = "${random_string.token_id.result}.${random_string.token_secret.result}"
}

# call the module for kubeadm cluster creation
module "install_kubeadm_cluster" {
  source              = "../.."
  master_public_ip    = local.master.public_dns
  master_private_ip   = local.master.private_dns
  tls_private_key_pem = local.master.tls_private_key_pem
  user                = local.user
  kubeadm_token       = local.token
  cni_pluggin         = "flannel" # calico or flannel
  loadbalancer_plugin = "metalLB"
  workers             = local.workers
}

# left part of the kubeadm token.
resource "random_string" "token_id" {
  length  = 6
  special = false
  upper   = false
}

# right part of the kubeadm token.
resource "random_string" "token_secret" {
  length  = 16
  special = false
  upper   = false
}
