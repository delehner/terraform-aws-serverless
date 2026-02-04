locals {
  nonproduction_domain    = "${var.application_name}-${var.environment}.${var.application_domain}"
  production_domain = "${var.application_name}.${var.application_domain}"
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

  domain_name = var.environment != "production" ? local.nonproduction_domain : local.production_domain

  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.issued[0].arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_route53_record" "application_without_health_check" {
  count = var.health_check_enabled || var.environment == "local" ? 0 : 1

  name    = aws_apigatewayv2_domain_name.application[0].domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.selected[0].zone_id

  latency_routing_policy {
    region = data.aws_region.current.name
  }

  set_identifier = "${data.aws_region.current.name}-${var.application_name}-${var.environment}.${var.application_domain}"

  alias {
    name                   = aws_apigatewayv2_domain_name.application[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.application[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_health_check" "application" {
  count = var.health_check_enabled && var.environment != "local" ? 1 : 0

  fqdn              = "${aws_apigatewayv2_api.api[0].id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = var.health_check_path
  failure_threshold = var.health_check_threshold
  request_interval  = var.health_check_interval
}

resource "aws_route53_record" "application_with_health_check" {
  count = var.health_check_enabled && var.environment != "local" ? 1 : 0

  name            = aws_apigatewayv2_domain_name.application[0].domain_name
  type            = "A"
  zone_id         = data.aws_route53_zone.selected[0].zone_id
  health_check_id = aws_route53_health_check.application[0].id

  latency_routing_policy {
    region = data.aws_region.current.name
  }

  set_identifier = var.environment != "production" ? "${data.aws_region.current.name}-${local.nonproduction_domain}" : "${data.aws_region.current.name}-${local.production_domain}"

  alias {
    name                   = aws_apigatewayv2_domain_name.application[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.application[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
