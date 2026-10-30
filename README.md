# Terraform - Serverless Module

This Terraform module provides all the necessary resources for deploying a serverless architecture on AWS.

## Usage

Here's a code example of how you can use this module:

```hcl
module "serverless" {
  source  = "app.terraform.io/<organization>/serverless/aws"
  version = "~> 1.1"

  application_name   = "serverless-boilerplate"
  environment        = "development"
  application_domain = "nexing.com"
}
```

## API hostname

By default the module derives the API Gateway custom domain from the
application name and environment:

- `<application_name>-<environment>.<application_domain>` outside production
  (e.g. `app-development.example.com`);
- `<application_name>.<application_domain>` in production
  (e.g. `app.example.com`).

Set `custom_domain_name` to choose the hostname yourself, for example when
the production web app already uses `<application_name>.<application_domain>`:

```hcl
module "serverless" {
  source  = "app.terraform.io/<organization>/serverless/aws"
  version = "~> 1.3"

  application_name   = "app"
  environment        = "production"
  application_domain = "example.com"
  custom_domain_name = "app-api.example.com"
}
```

The hostname must be exactly one level below `application_domain`: the
module looks up the wildcard certificate `*.<application_domain>` and
creates the alias record in the `<application_domain>` hosted zone. A
lowercase hostname without scheme, path, port or trailing dot is required.
The input is ignored when `environment` is `"local"`.

Switching an existing deployment from the derived hostname to a custom one
replaces the API Gateway custom domain, its API mapping and the Route53
alias record (the old hostname stops resolving).

## CloudFront-front pattern

AWS WAFv2 cannot attach to API Gateway HTTP API v2 directly. To put WAF
in front of the API, run a CloudFront distribution as the public edge,
use the API GW as the origin, and let a downstream module own the
public Route53 record so it doesn't collide with this module's alias.

Set `enable_custom_domain_route53_record = false` to suppress the
registry record. The API GW custom domain itself stays created — only
the public DNS record is gated — so the new outputs below are still
populated and usable as origins.

### New outputs

- `api_gateway_invoke_dns_name` — `<api-id>.execute-api.<region>.amazonaws.com` (cleanest CloudFront origin).
- `api_gateway_stage_name` — `"$default"` (the implicit stage created via the API's `target` attribute).
- `api_gateway_custom_domain_name` — e.g. `api-staging.example.com`, alternative origin shape.
- `api_gateway_custom_domain_target_dns` / `api_gateway_custom_domain_zone_id` — regional alias target, if you want to point a separate hostname at the API GW directly.

### Example wiring

```hcl
module "serverless" {
  source  = "app.terraform.io/<organization>/serverless/aws"
  version = "~> 1.1"

  application_name                    = "serverless-boilerplate"
  environment                         = "staging"
  application_domain                  = "example.com"
  enable_custom_domain_route53_record = false
}

resource "aws_cloudfront_distribution" "edge" {
  # ...
  origin {
    domain_name = module.serverless.api_gateway_invoke_dns_name
    origin_id   = "apigw"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  aliases = ["api-staging.example.com"]
  # ... web_acl_id, viewer_certificate, default_cache_behavior, etc.
}

resource "aws_route53_record" "edge" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "api-staging.example.com"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.edge.domain_name
    zone_id                = aws_cloudfront_distribution.edge.hosted_zone_id
    evaluate_target_health = false
  }
}
```

## Inputs

| Name | Description | Type | Default |
| ---- | ----------- | ---- | ------- |
| `application_name` | Application's name. | `string` | required |
| `environment` | Environment where the resource is running (`"local"` creates no AWS resources). | `string` | required |
| `application_domain` | The domain of the public hosted zone (and of the wildcard certificate). | `string` | required |
| `custom_domain_name` | API hostname. Null derives it from `application_name` and `environment` (see [API hostname](#api-hostname)). Must be one level below `application_domain`. | `string` | `null` |
| `application_runtime` | Lambda runtime. | `string` | `"provided.al2"` |
| `processor_architecture` | Lambda architecture. | `string` | `"arm64"` |
| `application_handler` | Lambda handler. | `string` | `"bootstrap"` |
| `protocol_type` | API Gateway protocol type. | `string` | `"HTTP"` |
| `log_retention_in_days` | CloudWatch log retention in days. | `number` | `7` |
| `lambda_timeout` | Lambda timeout in seconds. | `number` | `30` |
| `concurrent_executions` | Reserved concurrent executions (`-1` for unreserved). | `number` | `-1` |
| `provisioned_concurrent_executions` | Provisioned concurrency (creates an alias when `>= 1`). | `number` | `0` |
| `function_version` | Lambda version the alias points to. | `string` | `"1"` |
| `health_check_enabled` | Create a Route53 health check and attach it to the alias record. | `bool` | `false` |
| `health_check_path` | Health check path. | `string` | `"/health"` |
| `health_check_threshold` | Health check failure threshold. | `string` | `"2"` |
| `health_check_interval` | Health check interval in seconds. | `string` | `"30"` |
| `events` | Events the application emits (one FIFO SNS topic each). | `list(string)` | `[]` |
| `enable_custom_domain_route53_record` | Create the Route53 alias record for the API hostname. | `bool` | `true` |
| `vpc_subnet_ids` | Private subnets to run the Lambda in a VPC. Empty keeps it outside any VPC. | `list(string)` | `[]` |
| `vpc_security_group_ids` | Security groups for the Lambda's VPC ENIs. | `list(string)` | `[]` |

## Outputs

| Name | Description |
| ---- | ----------- |
| `lambda` | Application Lambda (list, empty when `environment` is `"local"`). |
| `lambda_role` | Lambda execution role. |
| `lambda_logs` | Lambda CloudWatch log group. |
| `api_gateway` | API Gateway HTTP API. |
| `api_gateway_mapping` | API Gateway API mapping. |
| `api_gateway_invoke_dns_name` | `<api-id>.execute-api.<region>.amazonaws.com`. |
| `api_gateway_stage_name` | Always `"$default"`. |
| `api_gateway_custom_domain_name` | API hostname (derived or `custom_domain_name`). |
| `api_gateway_custom_domain_target_dns` | Regional alias target of the custom domain. |
| `api_gateway_custom_domain_zone_id` | Hosted-zone ID of the regional alias target. |
