# Current account
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

locals {
  mutability = var.mutability
  region     = data.aws_region.current.name
  tags       = merge({ module = "ecr" }, var.tags)
}

# create ECR repositories
resource "aws_ecr_repository" "ecr" {
  for_each             = var.repositories
  name                 = each.key
  image_tag_mutability = local.mutability
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_id
  }
  tags         = local.tags
  force_delete = true #(Optional) If true, will delete the repository even if it contains images. Defaults to false.
}

# lifecycle policy
resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  for_each   = aws_ecr_repository.ecr
  repository = each.key

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

# IAM policy
data "aws_iam_policy_document" "iam_ecr" {
  statement {
    sid    = "new policy"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
    ]
  }
}

resource "aws_ecr_repository_policy" "ecr_policy" {
  for_each   = aws_ecr_repository.ecr
  repository = each.key
  policy     = data.aws_iam_policy_document.iam_ecr.json
}
# Copy images
resource "null_resource" "copy_images" {
  for_each = var.repositories
  triggers = {
    state = join("-", [
      each.key, var.repositories[each.key].image, var.repositories[each.key].tag
    ])
  }
  provisioner "local-exec" {
    command = <<-EOT
aws ecr get-login-password --profile ${var.aws_profile} --region ${local.region}  | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com
aws ecr-public get-login-password --profile ${var.aws_profile} --region us-east-1  | docker login --username AWS --password-stdin public.ecr.aws
if [ -z "$(docker images -q '${var.repositories[each.key].image}:${var.repositories[each.key].tag}')" ]
then
  if ! docker pull ${var.repositories[each.key].image}:${var.repositories[each.key].tag}
  then
    echo "cannot download image ${var.repositories[each.key].image}:${var.repositories[each.key].tag}"
    exit 1
  fi
fi
if ! docker tag ${var.repositories[each.key].image}:${var.repositories[each.key].tag} ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${each.key}:${var.repositories[each.key].tag}
then
  echo "cannot tag image ${var.repositories[each.key].image}:${var.repositories[each.key].tag} to ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${each.key}:${var.repositories[each.key].tag}"
  exit 1
fi
if ! docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${each.key}:${var.repositories[each.key].tag}
then
  echo "cannot push image ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${each.key}:${var.repositories[each.key].tag}"
  exit 1
fi
EOT
  }
  depends_on = [
    aws_ecr_repository.ecr
  ]
}
