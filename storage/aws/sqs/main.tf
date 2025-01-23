locals {
  prefix = var.prefix
  region = var.region
  tags   = merge(var.tags, { module = "amazon-sqs" })
}


data "aws_iam_policy_document" "sqs" {
  statement {
    sid = "SqsAdmin"
    actions = [
      "sqs:CreateQueue",
      "sqs:DeleteQueue",
      "sqs:ListQueues",
      "sqs:GetQueueAttributes",
      "sqs:PurgeQueue",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility"
    ]
    effect    = "Allow"
    resources = ["arn:aws:sqs:::${local.prefix}*"]
  }
}

resource "aws_iam_policy" "sqs" {
  name_prefix = "${local.prefix}-sqs-admin"
  description = "Policy for allowing SQS admin access"
  policy      = data.aws_iam_policy_document.sqs.json
  tags        = local.tags
}

resource "aws_iam_policy_attachment" "sqs" {
  name       = "${local.prefix}-sqs"
  roles      = [var.service_account_role_name]
  policy_arn = aws_iam_policy.sqs.arn
}
