# Complete example

Cloud SQL for PostgreSQL instance with every option: regional availability, point-in-time recovery, extra flags and
a maintenance window.

```bash
terraform init
terraform apply -var project=<project> -var network=projects/<project>/global/networks/<name>
```
