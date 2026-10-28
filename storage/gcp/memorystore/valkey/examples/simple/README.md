## Simple Valkey

An instance with the default settings (TLS, no authentication), in a VPC with a service connection policy.
Uses the [valkey module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```
