# Outputs for Manual DNS Validation

output "certificate_arn" {
  description = "ARN of the ACM certificate (application region)"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "validation_records" {
  description = "DNS records required for validation (application region)"
  value = [
    for dvo in aws_acm_certificate.this.domain_validation_options : {
      domain_name           = dvo.domain_name
      resource_record_name  = dvo.resource_record_name
      resource_record_type  = dvo.resource_record_type
      resource_record_value = dvo.resource_record_value
    }
  ]
}

output "cloudfront_certificate_arn" {
  description = "ARN of the us-east-1 certificate for CloudFront and API Gateway"
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}

output "cloudfront_validation_records" {
  description = "DNS records required for validation (us-east-1)"
  value = [
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : {
      domain_name           = dvo.domain_name
      resource_record_name  = dvo.resource_record_name
      resource_record_type  = dvo.resource_record_type
      resource_record_value = dvo.resource_record_value
    }
  ]
}
