## Complete GCS

A dual-region versioned bucket with lifecycle rules, no soft delete, access logs and IAM roles for the current user.
Uses the [gcs module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```
