## Complete Service Account

A GKE cluster, and a test pod running as a Kubernetes service account that impersonates an IAM service account with
Redis and Pub/Sub roles. Uses the [service-account module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```
