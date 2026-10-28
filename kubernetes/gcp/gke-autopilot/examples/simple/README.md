## Simple GKE Autopilot

A regional Autopilot cluster with the default settings: private nodes, public control plane endpoint.
Uses the [gke-autopilot module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```
