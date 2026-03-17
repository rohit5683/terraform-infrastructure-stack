output "certificate_arn" {
  value = aws_acm_certificate.api_cert.arn
}

output "domain_validation_options" {
  value = aws_acm_certificate.api_cert.domain_validation_options
}
