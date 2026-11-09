# Simple example

Cloud SQL for PostgreSQL instance with the default values, reached from `network` through Private Service Connect.

```bash
terraform init
terraform apply -var project=<project> -var network=projects/<project>/global/networks/<name>
```
