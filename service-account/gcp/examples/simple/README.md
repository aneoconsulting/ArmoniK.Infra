## Simple Service Account

A project role for a Kubernetes service account created by another module, through Workload Identity Federation
for GKE. Uses the [service-account module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```
