This module facilitates the creation of a GCP service account assigned with the "workLoadIdentityUser" role, along with other necessary roles. Additionally, it establishes a Kubernetes service account that assumes the identity of the GCP service account. This Kubernetes service account is meant to be associated with the pods within the GKE cluster.

## List of inputs

- Kubernetes namespace
- Name of GCP service account
- Name of kubernetes service account
- Project ID
- List of roles

## List of outputs

- Kubernetes namespace
- GCP and Kubernetes service accounts names

