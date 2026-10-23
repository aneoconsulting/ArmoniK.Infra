## Simple VPC

Two subnets, one behind Cloud NAT. Uses the [vpc module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```
