# ==============================================================================
# ACM (AWS Certificate Manager) Module
# ==============================================================================
# Provisions SSL/TLS Certificates via DNS Validation.
#
# REGIONAL USAGE:
# 1. Application Region (e.g. eu-north-1): Used by Load Balancers (ALB)
# 2. US-EAST-1 Region (Global): Used by CloudFront and API Gateway Custom Domains
#    (AWS enforces certificates for Edge services to be in us-east-1)

# ------------------------------------------------------------------------------
# 1. Main Region Certificate (ALB)
# ------------------------------------------------------------------------------
resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name != null ? var.domain_name : (var.env == "prod" ? "*.rvdevops.com" : "*.${var.env}.rvdevops.com")
  validation_method = "DNS"

  subject_alternative_names = var.env == "prod" ? ["www.app.rvdevops.com"] : []

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn
}

# DNS Validation Record (Main Region)
resource "aws_route53_record" "validation" {
  for_each = var.enable_route53_dns ? {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}


# ------------------------------------------------------------------------------
# 2. US-EAST-1 Certificate (CloudFront / API Gateway)
# ------------------------------------------------------------------------------
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.useast1
  domain_name       = var.domain_name != null ? var.domain_name : (var.env == "prod" ? "*.rvdevops.com" : "*.${var.env}.rvdevops.com")
  validation_method = "DNS"

  subject_alternative_names = var.env == "prod" ? ["www.app.rvdevops.com"] : []

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Purpose = "CloudFront and API Gateway"
  })
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider        = aws.useast1
  certificate_arn = aws_acm_certificate.cloudfront.arn
}

# DNS Validation Record (US-EAST-1)
resource "aws_route53_record" "cloudfront_validation" {
  for_each = var.enable_route53_dns ? {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}
