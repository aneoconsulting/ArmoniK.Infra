# MongoDB Atlas AWS PrivateLink Terraform Module

This module creates a MongoDB Atlas cluster with AWS PrivateLink integration.

## Usage

```hcl
module "atlas" {
  source              = "../atlas"
  atlas_public_key    = "<ATLAS_PUBLIC_KEY>"
  atlas_private_key   = "<ATLAS_PRIVATE_KEY>"
  atlas_org_id        = "<ATLAS_ORG_ID>"
  project_name        = "my-project"
  cluster_name        = "my-cluster"
  atlas_region        = "EU_WEST_1"
  instance_size       = "M10"
  aws_region          = "eu-west-1"
  aws_profile         = "default"
  vpc_id              = "<VPC_ID>"
  subnet_ids          = ["<SUBNET_ID1>", "<SUBNET_ID2>"]
  security_group_ids  = ["<SG_ID>"]
}
```


---
