locals {
  nonproduction_domain = "${var.application_name}-${var.environment}.${var.application_domain}"
  production_domain    = "${var.application_name}.${var.application_domain}"

  # Hostname derived from the application name and environment (the behaviour
  # before custom_domain_name existed).
  derived_domain = var.environment != "production" ? local.nonproduction_domain : local.production_domain

  # custom_domain_name, when set, replaces the derived hostname.
  api_domain = var.custom_domain_name != null ? var.custom_domain_name : local.derived_domain
}

data "aws_route53_zone" "selected" {
  count = var.environment == "local" ? 0 : 1

  name         = var.application_domain
  private_zone = false
}

data "aws_acm_certificate" "issued" {
  count = var.environment == "local" ? 0 : 1

  domain   = "*.${var.application_domain}"
  statuses = ["ISSUED"]
}

resource "aws_apigatewayv2_domain_name" "application" {
  count = var.environment == "local" ? 0 : 1

  domain_name = local.api_domain

  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.issued[0].arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  lifecycle {
    # The certificate is the wildcard *.<application_domain> and the record
    # goes into the <application_domain> zone, so a custom hostname must be
    # exactly one label below application_domain. (Checked here and not in the
    # variable validation because cross-variable validation needs Terraform
    # >= 1.9.)
    precondition {
      condition = var.custom_domain_name == null || (
        endswith(coalesce(var.custom_domain_name, "-"), ".${var.application_domain}") &&
        length(split(".", coalesce(var.custom_domain_name, "-"))) == length(split(".", var.application_domain)) + 1
      )
      error_message = "custom_domain_name must be a single-level subdomain of application_domain (for example api.<application_domain>), because the module uses the wildcard certificate *.<application_domain>."
    }
  }
}

resource "aws_route53_record" "application_without_health_check" {
  count = var.health_check_enabled || var.environment == "local" || !var.enable_custom_domain_route53_record ? 0 : 1

  name    = aws_apigatewayv2_domain_name.application[0].domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.selected[0].zone_id

  latency_routing_policy {
    region = data.aws_region.current.region
  }

  set_identifier = var.custom_domain_name != null ? "${data.aws_region.current.region}-${var.custom_domain_name}" : "${data.aws_region.current.region}-${var.application_name}-${var.environment}.${var.application_domain}"

  alias {
    name                   = aws_apigatewayv2_domain_name.application[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.application[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_health_check" "application" {
  count = var.health_check_enabled && var.environment != "local" ? 1 : 0

  fqdn              = "${aws_apigatewayv2_api.api[0].id}.execute-api.${data.aws_region.current.region}.amazonaws.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = var.health_check_path
  failure_threshold = var.health_check_threshold
  request_interval  = var.health_check_interval
}

resource "aws_route53_record" "application_with_health_check" {
  count = var.health_check_enabled && var.environment != "local" && var.enable_custom_domain_route53_record ? 1 : 0

  name            = aws_apigatewayv2_domain_name.application[0].domain_name
  type            = "A"
  zone_id         = data.aws_route53_zone.selected[0].zone_id
  health_check_id = aws_route53_health_check.application[0].id

  latency_routing_policy {
    region = data.aws_region.current.region
  }

  set_identifier = "${data.aws_region.current.region}-${local.api_domain}"

  alias {
    name                   = aws_apigatewayv2_domain_name.application[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.application[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
