# ==============================================================================
# Route 53 Module
# ==============================================================================
# Manages DNS Records for the application.
# Configures A-Record Aliases to point domains to AWS Load Balancers or CloudFront.

data "aws_route53_zone" "this" {
  name = var.dns_zone_name
}

resource "aws_route53_record" "alias" {
  for_each = var.records

  zone_id = data.aws_route53_zone.this.zone_id
  name    = each.key
  type    = "A"

  alias {
    name                   = each.value.target_dns
    zone_id                = each.value.target_zone_id
    evaluate_target_health = true
  }
}
