## Simple GKE Cluster

A zonal cluster with the default settings: Dataplane V2, a small system pool, private nodes, and no public IP endpoint
(the control plane is reachable from the VPC only). Uses the [gke module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```
