# Changelog

## v1.3.0

### Added
- New input `custom_domain_name` (default `null` — preserves the current behaviour). When set, it replaces the derived API hostname (`<application_name>-<environment>.<application_domain>`, or `<application_name>.<application_domain>` in production) on the API Gateway custom domain and its Route53 alias record. Use it when the derived hostname is taken, e.g. by the production web app.
- Validation: `custom_domain_name` must be a lowercase hostname without scheme, path, port, wildcard or trailing dot; a precondition on the custom domain also requires it to be exactly one level below `application_domain`, because the module uses the wildcard certificate `*.<application_domain>` and the `<application_domain>` hosted zone.

### Notes
- No breaking changes. With `custom_domain_name` unset, the hostname and the Route53 `set_identifier` values are the same as in v1.2.0, so `terraform plan` shows zero diff.
- Setting `custom_domain_name` on an existing deployment replaces the API Gateway custom domain, its API mapping and the alias record; the old hostname stops resolving.
- `api_gateway_custom_domain_name` now returns the custom hostname when one is set.

## v1.2.0

### Added
- VPC feature flag. New inputs `vpc_subnet_ids` and `vpc_security_group_ids` (both default `[]`). When `vpc_subnet_ids` is non-empty, the Lambda is attached to the VPC (a `vpc_config` block) and the role gains `AWSLambdaVPCAccessExecutionRole` for ENI management. Empty (default) preserves the current non-VPC behaviour. Use it to reach VPC-only resources such as an RDS/Aurora cluster behind an RDS Proxy.

## v1.1.0

### Added
- New input `enable_custom_domain_route53_record` (default `true` — preserves current behaviour). Set `false` when a downstream module (e.g. a CloudFront-front for WAFv2) owns the public hostname and the registry's alias would collide.
- New outputs to support a CloudFront-front pattern:
  - `api_gateway_invoke_dns_name` — `<api-id>.execute-api.<region>.amazonaws.com`, intended as a CloudFront origin.
  - `api_gateway_stage_name` — always `"$default"` (created implicitly via the `target` attribute on `aws_apigatewayv2_api`).
  - `api_gateway_custom_domain_name` — the API GW custom domain hostname; returned even when the Route53 record is disabled.
  - `api_gateway_custom_domain_target_dns` and `api_gateway_custom_domain_zone_id` — regional alias target / hosted-zone ID for the custom domain.

### Notes
- No breaking changes. With no flag set and no consumer using the new outputs, `terraform plan` shows zero diff.
- The API GW custom domain (`aws_apigatewayv2_domain_name`) stays created even when the flag is `false` — only the public DNS record is gated. The custom domain remains available as an alternative CloudFront origin shape.

## v1.0.1
- Fix Lambda `InvalidZipFileException` from racing dummy zip writes.

## v1.0.0
- Align module defaults with consumer usage; fix IAM bugs; pin providers.

## v0.0.1
- Initial release.
