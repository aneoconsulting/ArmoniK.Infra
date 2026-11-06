## Simple Valkey

An instance with the default settings (TLS, no authentication), in a VPC with a service connection policy.
Uses the [valkey module](../..). The CA secret for Core is created in the `default` namespace of the cluster of
`~/.kube/config`.

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```
