## Simple pull-through caches

The default upstreams (Docker Hub, GHCR, Quay, registry.k8s.io, public ECR), anonymous, without cleanup. Uses the
[artifact-registry-remote module](../..).

```bash
terraform init
terraform apply -var project=<project>
docker pull $(terraform output -json urls | jq -r .quay)/prometheus/node-exporter:v1.12.1
terraform destroy -var project=<project>
```

The pull needs `gcloud auth configure-docker <region>-docker.pkg.dev`.
