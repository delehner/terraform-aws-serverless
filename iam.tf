
resource "aws_iam_role" "application" {
  count = var.environment == "local" ? 0 : 1

  name               = "${data.aws_region.current.region}-${var.application_name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy[0].json

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  count = var.environment == "local" ? 0 : 1

  statement {
    sid = "AssumeRole"

    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "application" {
  count = var.environment == "local" ? 0 : 1

  role       = aws_iam_role.application[0].id
  policy_arn = aws_iam_policy.application[0].arn
}

# When the VPC feature flag is on, the Lambda needs to manage the ENIs it runs
# on. AWSLambdaVPCAccessExecutionRole grants exactly ec2:*NetworkInterface* (+
# logs). Attached only when vpc_subnet_ids is set, so non-VPC deployments keep
# a minimal role.
resource "aws_iam_role_policy_attachment" "vpc_access" {
  count = var.environment == "local" ? 0 : (length(var.vpc_subnet_ids) > 0 ? 1 : 0)

  role       = aws_iam_role.application[0].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "application" {
  count = var.environment == "local" ? 0 : 1

  name   = "${var.application_name}-${var.environment}-policy"
  policy = data.aws_iam_policy_document.application[0].json
}

data "aws_iam_policy_document" "application" {
  count = var.environment == "local" ? 0 : 1

  statement {
    sid = "CloudWatch"

    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }

  statement {
    sid = "SSM"

    effect = "Allow"

    actions = [
      "ssm:List*",
      "ssm:Get*",
    ]

    resources = [
      "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {
    sid = "SNS"

    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = [
      "arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {
    sid = "DynamoDB"

    effect = "Allow"

    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:GetItem",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListGlobalTables",
      "dynamodb:ListTables",
      "dynamodb:PartiQLDelete",
      "dynamodb:PartiQLInsert",
      "dynamodb:PartiQLSelect",
      "dynamodb:PartiQLUpdate",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
    ]

    resources = [
      "arn:aws:dynamodb:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*",
    ]
  }

  statement {
    sid = "SQS"

    effect = "Allow"

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:ChangeMessageVisibilityBatch",
      "sqs:DeleteMessage",
      "sqs:DeleteMessageBatch",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage"
    ]

    resources = [
      "arn:aws:sqs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {
    sid = "S3"

    effect = "Allow"

    actions = [
      "s3:*Object",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::*"
    ]
  }

  statement {
    sid = "SES"

    effect = "Allow"

    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]

    resources = [
      "*"
    ]
  }
}
