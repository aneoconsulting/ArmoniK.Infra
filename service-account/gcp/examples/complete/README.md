## Complete Service Account

A GKE cluster, a bucket readable by a Kubernetes service account, and a test pod running as that service account.
Uses the [service-account module](../..).

```bash
terraform init
terraform apply -var project=<project>
gcloud container clusters get-credentials $(terraform output -raw cluster_name) --zone <region>-a --project <project>
kubectl exec complete-sa-test -- gcloud storage ls $(terraform output -raw bucket_url)
terraform destroy -var project=<project>
```
