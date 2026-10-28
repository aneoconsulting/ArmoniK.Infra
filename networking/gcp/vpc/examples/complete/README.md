## Complete VPC

Subnets in several regions, a GKE subnet, a Memorystore service connection policy and the network settings. Uses
the [vpc module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```
