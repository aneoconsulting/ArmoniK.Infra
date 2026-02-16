## Complete Kubeadm Example

The Terraform scripts use the module [kubeadm](../../kubeadm) to install and configure a Kubernetes cluster with `Kubeadm`.

First, you should have a list of barre metal ou virtual machines, and then you have to update values `PUBLIC_DNS_HERE`
, `PRIVATE_DNS_HERE` and `TLS_PRIVATE_KEY_FILE_HERE` in the file [terraform.tfvars](terraform.tfvars).



