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
