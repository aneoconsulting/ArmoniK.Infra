## Complete pull-through caches

Docker Hub authenticated with a token stored in Secret Manager (write-only, never in the state), Quay, and the Fluent
Bit registry as a custom upstream; a service account allowed to pull, and a 30-day cleanup of the cached images.
Uses the [artifact-registry-remote module](../..). Write-only attributes need Terraform 1.11 or later.

```bash
terraform init
terraform apply -var project=<project> -var dockerhub_username=<user> -var dockerhub_token=<token>
docker pull $(terraform output -json urls | jq -r .fluentbit)/fluent/fluent-bit:5.1.3
terraform destroy -var project=<project> -var dockerhub_username=<user> -var dockerhub_token=<token>
```
