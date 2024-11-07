# Current account
data "aws_caller_identity" "current" {}

data "aws_ecr_authorization_token" "current" {}

data "aws_region" "current" {}

locals {
  region                      = data.aws_region.current.name
  current_account             = data.aws_caller_identity.current.account_id
  only_pull_accounts_root     = formatlist("arn:aws:iam::%s:root", var.only_pull_accounts)
  push_and_pull_accounts_root = formatlist("arn:aws:iam::%s:root", var.push_and_pull_accounts)
  current_account_root        = format("arn:aws:iam::%s:root", local.current_account)
  pull_actions = [
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage",
    "ecr:BatchCheckLayerAvailability",
  ]
  push_actions = [
    "ecr:PutImage",
    "ecr:InitiateLayerUpload",
    "ecr:UploadLayerPart",
    "ecr:CompleteLayerUpload",
  ]
  admin_actions = [
    "ecr:DescribeRepositories",
    "ecr:ListImages",
    "ecr:GetRepositoryPolicy",
    "ecr:DeleteRepository",
    "ecr:BatchDeleteImage",
    "ecr:SetRepositoryPolicy",
    "ecr:DeleteRepositoryPolicy",
  ]
  lifecycle_policy = can(coalesce(var.lifecycle_policy)) ? jsonencode(var.lifecycle_policy) : null
  tags             = merge({ module = "ecr" }, var.tags)
}

# create ECR repositories
resource "aws_ecr_repository" "ecr" {
  for_each             = var.repositories
  name                 = each.key
  image_tag_mutability = var.mutability
  dynamic "image_scanning_configuration" {
    for_each = can(coalesce(var.scan_on_push)) ? [1] : []
    content {
      scan_on_push = var.scan_on_push
    }
  }
  dynamic "encryption_configuration" {
    for_each = can(coalesce(var.encryption_type)) ? [1] : []
    content {
      encryption_type = var.encryption_type
      kms_key         = var.encryption_type == "KMS" && can(coalesce(var.kms_key_id)) ? var.kms_key_id : null
    }
  }
  force_delete = var.force_delete
  tags         = local.tags
}

# Allows specific accounts to pull images
data "aws_iam_policy_document" "only_pull" {
  statement {
    sid    = "ElasticContainerRegistryOnlyPull"
    effect = "Allow"
    principals {
      identifiers = distinct(concat([local.current_account_root], local.only_pull_accounts_root))
      type        = "AWS"
    }
    actions = local.pull_actions
  }
}

# Allows specific accounts to push and pull images
data "aws_iam_policy_document" "push_and_pull" {
  statement {
    sid    = "ElasticContainerRegistryPushAndPull"
    effect = "Allow"
    principals {
      identifiers = distinct(concat([local.current_account_root], local.push_and_pull_accounts_root))
      type        = "AWS"
    }
    actions = distinct(concat(local.pull_actions, local.push_actions))
  }
}

# Allows current account manage repositories and images
data "aws_iam_policy_document" "admin" {
  statement {
    sid    = "ElasticContainerRegistryAdmin"
    effect = "Allow"
    principals {
      identifiers = [local.current_account_root]
      type        = "AWS"
    }
    actions = local.admin_actions
  }
}

# Policy document for ECR
data "aws_iam_policy_document" "permissions" {
  source_policy_documents = [
    data.aws_iam_policy_document.admin.json,
    data.aws_iam_policy_document.only_pull.json,
    data.aws_iam_policy_document.push_and_pull.json,
  ]
}

# Policy for ECR
resource "aws_ecr_repository_policy" "policy" {
  for_each   = aws_ecr_repository.ecr
  repository = each.key
  policy     = data.aws_iam_policy_document.permissions.json
}

# Lifecycle policy
resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  for_each   = can(coalesce(local.lifecycle_policy)) ? aws_ecr_repository.ecr : {}
  repository = each.key
  policy     = local.lifecycle_policy
}

# Push images
resource "skopeo2_copy" "copy_images" {
  for_each          = aws_ecr_repository.ecr
  source_image      = "docker://${var.repositories[each.key].image}:${var.repositories[each.key].tag}"
  destination_image = "docker://${each.value.repository_url}:${var.repositories[each.key].tag}"

  copy_all_images = true
  retries         = 10
  retry_delay     = 10

  depends_on = [generic_local_cmd.logout_public_ecr_login_private]
}

# This is to fix the auth token expired issue describe here: https://docs.aws.amazon.com/AmazonECR/latest/public/public-registries.html
resource "generic_local_cmd" "logout_public_ecr_login_private" {
  inputs = {
    profile         = var.aws_profile
    region          = local.region
    current_account = local.current_account
  }

  create {
    cmd = <<EOT
      docker logout public.ecr.aws
      aws ecr get-login-password --profile "$INPUT_profile" --region "$INPUT_region"  | docker login --username AWS --password-stdin "$INPUT_current_account".dkr.ecr."$INPUT_region".amazonaws.com    
      EOT
  }

  destroy {
    cmd = <<EOT
      docker logout "$INPUT_current_account".dkr.ecr."$INPUT_region".amazonaws.com    
      EOT
  }

  update {
    triggers = ["profile"]
    cmd      = <<EOT
      aws ecr get-login-password --profile "$INPUT_profile" --region "$INPUT_region"  | docker login --username AWS --password-stdin "$INPUT_current_account".dkr.ecr."$INPUT_region".amazonaws.com    
      EOT
  }
}
