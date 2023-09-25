
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  config_path = "${path.root}/generated/kubeconfig"
}

# package manager for kubernetes
provider "helm" {
  helm_driver = "configmap"
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    #token                  = module.eks.token
    insecure = false
    config_path = "${path.root}/generated/kubeconfig"
  }
}
