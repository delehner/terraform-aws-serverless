output "lambda" {
  value       = aws_lambda_function.application
  description = "Application lambda."
}

output "lambda_role" {
  value       = aws_iam_role.application
  description = "Application lambda role."
}

output "lambda_logs" {
  value       = aws_cloudwatch_log_group.application
  description = "Application lambda logs."
}

output "api_gateway" {
  value       = aws_apigatewayv2_api.api
  description = "API Gateway."
}

output "api_gateway_mapping" {
  value       = aws_apigatewayv2_api_mapping.api
  description = "API Gateway mapping."
}
