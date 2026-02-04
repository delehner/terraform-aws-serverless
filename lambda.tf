data "archive_file" "dummy" {
  type        = "zip"
  output_path = "./tmp/dummy.zip"
  source {
    content  = <<EOF
    just a dummy content
EOF
    filename = "dummy.rs"
  }
}


resource "aws_lambda_function" "application" {
  count = var.environment == "local" ? 0 : 1

  function_name                  = "${var.application_name}-${var.environment}"
  filename                       = data.archive_file.dummy.output_path
  source_code_hash               = data.archive_file.dummy.output_base64sha256
  handler                        = var.application_handler
  runtime                        = var.application_runtime
  architectures                  = [var.processor_architecture]
  role                           = aws_iam_role.application[0].arn
  reserved_concurrent_executions = var.concurrent_executions
  timeout                        = var.lambda_timeout
  publish                        = true

  environment {
    variables = {
      APPLICATION_NAME = var.application_name
      ENVIRONMENT      = var.environment
    }
  }

  lifecycle {
    ignore_changes = [
      tags,
      filename,
      source_code_hash
    ]
  }

  depends_on = [
    aws_cloudwatch_log_group.application[0],
  ]
}

resource "aws_lambda_alias" "application" {
  count = var.environment == "local" || var.provisioned_concurrent_executions <= 0 ? 0 : 1

  name             = "${var.application_name}-${var.environment}-alias"
  description      = "For Blue/Green deployment AND concurrency."
  function_name    = aws_lambda_function.application[0].arn
  function_version = var.function_version

  lifecycle {
    ignore_changes = [
      function_version
    ]
  }
}

resource "aws_lambda_provisioned_concurrency_config" "application" {
  count = var.environment == "local" || var.provisioned_concurrent_executions <= 0 ? 0 : 1

  function_name                     = aws_lambda_alias.application[0].function_name
  provisioned_concurrent_executions = var.provisioned_concurrent_executions
  qualifier                         = aws_lambda_alias.application[0].name
}

resource "aws_cloudwatch_log_group" "application" {
  count = var.environment == "local" ? 0 : 1

  name              = "/aws/lambda/${var.application_name}-${var.environment}"
  retention_in_days = var.log_retention_in_days
  
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
