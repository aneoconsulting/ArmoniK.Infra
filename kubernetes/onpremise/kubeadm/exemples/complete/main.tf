
locals {
  master = {
    name                = "master-1"
    public_dns          = "PUBLIC_DNS_HERE" # it can be private if you are in the dest network
    private_dns         = "PRIVATE_DNS_HERE"
    tls_private_key_pem = "my master node ssh private key"
  }
  workers = {
    "worker-1" = {
      "name"                = "worker-1"
      "labels"              = tolist(["workers", ])
      "taints"              = tolist(["workers", ])
      "public_dns"          = "PUBLIC_DNS_HERE" # it can be private if you are in the dest network
      "tls_private_key_pem" = "my worker-1 node ssh private key"
    },
    "worker-2" = {
      "name"                = "worker-2"
      "labels"              = tolist(["workers", ])
      "taints"              = tolist(["workers", ])
      "public_dns"          = "PUBLIC_DNS_HERE" # it can be private if you are in the dest network
      "tls_private_key_pem" = "my worker-2 node ssh private key"
    }
  }
  user  = "ec2-user" #default redhat user
  token = "${random_string.token_id.result}.${random_string.token_secret.result}"
}

# call the module for kubeadm cluster creation
module "install_kubeadm_cluster" {
  source                      = "../.."
  master_public_ip            = local.master.public_dns
  master_private_ip           = local.master.private_dns
  tls_private_key_pem_content = file(local.master.tls_private_key_pem)
  user                        = local.user
  kubeadm_token               = local.token
  cni_pluggin                 = "flannel" # calico or flannel
  loadbalancer_plugin         = "metalLB"
  workers                     = local.workers
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

#------------------------------------------------------------------------------#
# Download kubeconfig file from master node to local machine
#------------------------------------------------------------------------------#
resource "null_resource" "download_kubeconfig_file" {
  provisioner "local-exec" {
    command = <<EOF
    cp ${local.master.tls_private_key_pem} $HOME/cluster_private_key.pem
    chmod 400 $HOME/cluster_private_key.pem
    scp -i $HOME/cluster_private_key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.user}@${local.master.public_dns}:/tmp/admin.conf $HOME/.kube/config_remote
    
    #export KUBECONFIG=$HOME/.kube/config_remote
    rm $HOME/cluster_private_key.pem
    EOF
  }
  depends_on = [
    module.install_kubeadm_cluster
  ]
}