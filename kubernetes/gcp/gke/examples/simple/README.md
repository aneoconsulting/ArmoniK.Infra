## Simple GKE

A zonal cluster with the default settings: private nodes, public control plane endpoint, Dataplane V2.
Uses the [gke module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```
