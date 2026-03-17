provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "api_cert" {
  provider          = aws.useast1
  domain_name       = var.domain_name
  validation_method = "DNS"
  tags              = var.tags
}
