locals {
  script_install_docker     = "install_docker.sh"
  script_install_kubernetes = "install_kubernetes.sh"
}

resource "null_resource" "install_kubernetes_cluster_node_masters" {
  connection {
    type        = "ssh"
    user        = var.user
    private_key = var.tls_private_key_pem
    host        = var.public_ip
    port        = 22
  }
  provisioner "file" {
    content = templatefile("${path.module}/scripts/${local.script_install_docker}",
      {
        master_public_ip  = var.master_public_ip
        master_private_ip = var.master_private_ip
        token             = var.kubeadm_token
        node              = "master"
        worker_name       = var.worker_name
        user              = var.user
        cni_pluggin       = var.cni_pluggin
    })
    destination = "/tmp/${local.script_install_docker}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo /bin/bash /tmp/${local.script_install_docker}"
    ]
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/${local.script_install_kubernetes}",
      {
        master_public_ip    = var.master_public_ip
        master_private_ip   = var.master_private_ip
        token               = var.kubeadm_token
        node                = "master"
        worker_name         = var.worker_name
        user                = var.user
        cni_pluggin         = var.cni_pluggin
        loadbalancer_plugin = var.loadbalancer_plugin
    })
    destination = "/tmp/${local.script_install_kubernetes}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo /bin/bash /tmp/${local.script_install_kubernetes}"
    ]
  }
}

