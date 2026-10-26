## Complete GKE

A zonal cluster with a system pool and a tainted spot pool, secrets encrypted with Cloud KMS, an authorized network
on the public endpoint and the DNS endpoint open to IAM-authenticated callers. Uses the [gke module](../..).

```bash
terraform init
terraform apply -var project=<project> -var authorized_cidr_block=$(curl -s ifconfig.me)/32
terraform destroy -var project=<project> -var authorized_cidr_block=$(curl -s ifconfig.me)/32
```
