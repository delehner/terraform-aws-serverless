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

output "api_gateway_invoke_dns_name" {
  description = "Hostname of the API Gateway HTTP API v2 stage (<api-id>.execute-api.<region>.amazonaws.com). Use as the CloudFront origin domain. Null when environment is \"local\"."
  value       = try("${aws_apigatewayv2_api.api[0].id}.execute-api.${data.aws_region.current.region}.amazonaws.com", null)
}

output "api_gateway_stage_name" {
  description = "Name of the deployed API Gateway stage. Always \"$default\" — created implicitly via the target attribute on aws_apigatewayv2_api. Null when environment is \"local\"."
  value       = var.environment == "local" ? null : "$default"
}

output "api_gateway_custom_domain_name" {
  description = "Custom domain hostname configured on the API GW (e.g. api-staging.example.com). Returned even when the Route53 record is disabled — useful as a CloudFront origin if the consumer prefers it over the raw invoke URL."
  value       = try(aws_apigatewayv2_domain_name.application[0].domain_name, null)
}

output "api_gateway_custom_domain_target_dns" {
  description = "Regional alias target for the custom domain (use in a Route53 alias record). Null when no custom domain is configured."
  value       = try(aws_apigatewayv2_domain_name.application[0].domain_name_configuration[0].target_domain_name, null)
}

output "api_gateway_custom_domain_zone_id" {
  description = "Hosted-zone ID of the regional alias target (paired with target_dns for an alias record)."
  value       = try(aws_apigatewayv2_domain_name.application[0].domain_name_configuration[0].hosted_zone_id, null)
}
