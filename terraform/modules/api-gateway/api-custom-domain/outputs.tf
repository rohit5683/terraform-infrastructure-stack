output "api_gateway_target_domain" {
  value = aws_apigatewayv2_domain_name.this.domain_name_configuration[0].target_domain_name
}

output "api_gateway_hosted_zone_id" {
  value = aws_apigatewayv2_domain_name.this.domain_name_configuration[0].hosted_zone_id
}
