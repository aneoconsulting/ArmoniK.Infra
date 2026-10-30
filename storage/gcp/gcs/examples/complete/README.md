## Complete GCS

A dual-region bucket with lifecycle rules, a retention policy, a website, CORS, ACLs and IAM roles for the current
user, and no soft delete. Uses the [gcs module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```
