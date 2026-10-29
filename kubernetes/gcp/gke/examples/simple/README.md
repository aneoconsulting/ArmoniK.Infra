## Simple GKE

A zonal cluster with the default settings: private nodes, no public IP endpoint (the
control plane is reachable from the VPC only), Dataplane V2.
Uses the [gke module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```
