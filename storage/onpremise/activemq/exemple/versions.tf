terraform {
  required_version = ">= 1.0"
}
provider "kubernetes" {
  config_path    = "/home/adem/.kube/config"
  config_context = "default"

}