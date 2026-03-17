# ==============================================================================
# API Gateway Custom Domain Module
# ==============================================================================
# Maps a commercially friendly domain name (e.g. api.rvdevops.com) to the API Gateway.
# - Requires a certificate in the SAME region as the API Gateway (unlike CloudFront).

resource "aws_apigatewayv2_domain_name" "this" {
  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = var.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = var.tags
}

# Mapping
# Connects the Domain Name to specific API ID and Stage.
resource "aws_apigatewayv2_api_mapping" "this" {
  api_id      = var.api_id
  domain_name = aws_apigatewayv2_domain_name.this.domain_name
  stage       = var.stage_name
}
