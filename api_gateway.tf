resource "aws_apigatewayv2_api" "api" {
  count = var.environment == "local" ? 0 : 1

  name          = "${var.application_name}-${var.environment}"
  protocol_type = var.protocol_type
  target        = var.provisioned_concurrent_executions >= 1 ? aws_lambda_alias.application[0].arn : aws_lambda_function.application[0].arn

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "aws_lambda_permission" "apigw" {
  count = var.environment == "local" ? 0 : 1

  action        = "lambda:InvokeFunction"
  function_name = var.provisioned_concurrent_executions >= 1 ? aws_lambda_alias.application[0].arn : aws_lambda_function.application[0].arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api[0].execution_arn}/*/*"
}

resource "aws_apigatewayv2_api_mapping" "api" {
  count = var.environment == "local" ? 0 : 1

  api_id      = aws_apigatewayv2_api.api[0].id
  domain_name = aws_apigatewayv2_domain_name.application[0].id
  stage       = "$default"
}
