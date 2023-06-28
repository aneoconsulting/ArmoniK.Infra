# create ECR repositories
resource "aws_ecr_repository" "ecr" {
  count = length(var.repositories)
  name  = var.repositories[count.index].name
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

# IAM policy

data "aws_iam_policy_document" "iam-ecr" {
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
  repository = aws_ecr_repository.ecr.name
  policy     = data.aws_iam_policy_document.iam-ecr.json
}

# Copy images
/*resource "null_resource" "copy_images" {
  count = length(var.repositories)
  triggers = {
    state = join("-", [
      var.repositories[count.index].name, var.repositories[count.index].image, var.repositories[count.index].tag
    ])
  }
  provisioner "local-exec" {
    command = <<-EOT
aws ecr get-login-password --profile ${var.profile} --region ${local.region}  | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com
aws ecr-public get-login-password --profile ${var.profile} --region us-east-1  | docker login --username AWS --password-stdin public.ecr.aws
if [ -z "$(docker images -q '${var.repositories[count.index].image}:${var.repositories[count.index].tag}')" ]
then
  if ! docker pull ${var.repositories[count.index].image}:${var.repositories[count.index].tag}
  then
    echo "cannot download image ${var.repositories[count.index].image}:${var.repositories[count.index].tag}"
    exit 1
  fi
fi
if ! docker tag ${var.repositories[count.index].image}:${var.repositories[count.index].tag} ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.repositories[count.index].name}:${var.repositories[count.index].tag}
then
  echo "cannot tag image ${var.repositories[count.index].image}:${var.repositories[count.index].tag} to ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.repositories[count.index].name}:${var.repositories[count.index].tag}"
  exit 1
fi
if ! docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.repositories[count.index].name}:${var.repositories[count.index].tag}
then
  echo "cannot push image ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.repositories[count.index].name}:${var.repositories[count.index].tag}"
  exit 1
fi
EOT
  }
  depends_on = [
    aws_ecr_repository.ecr
  ]
}*/

# Copy images
resource "null_resource" "copy_images" {
  for_each = var.repositories
  triggers = {
    state = join("-", [
      var.repositories[each.key], var.repositories[each.key].image, var.repositories[each.key].tag
    ])
  }
  provisioner "local-exec" {
    command = <<-EOT
aws ecr get-login-password --profile ${var.profile} --region ${local.region}  | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com
aws ecr-public get-login-password --profile ${var.profile} --region us-east-1  | docker login --username AWS --password-stdin public.ecr.aws
if [ -z "$(docker images -q '${var.repositories[each.key].image}:${var.repositories[each.key].tag}')" ]
then
  if ! docker pull ${var.repositories[each.key].image}:${var.repositories[each.key].tag}
  then
    echo "cannot download image ${var.repositories[each.key].image}:${var.repositories[each.key].tag}"
    exit 1
  fi
fi
if ! docker tag ${var.repositories[each.key].image}:${var.repositories[each.key].tag} ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.repositories[each.key].name}:${var.repositories[each.key].tag}
then
  echo "cannot tag image ${var.repositories[each.key].image}:${var.repositories[each.key].tag} to ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.repositories[each.key]}:${var.repositories[each.key].tag}"
  exit 1
fi
if ! docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.repositories[each.key]}:${var.repositories[each.key].tag}
then
  echo "cannot push image ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.repositories[each.key]}:${var.repositories[each.key].tag}"
  exit 1
fi
EOT
  }
  depends_on = [
    aws_ecr_repository.ecr
  ]
}
