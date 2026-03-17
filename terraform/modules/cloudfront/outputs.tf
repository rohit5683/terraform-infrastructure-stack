output "distribution_id" {
  value       = aws_cloudfront_distribution.frontend.id
  description = "CloudFront distribution ID"
}

output "distribution_domain_name" {
  value       = aws_cloudfront_distribution.frontend.domain_name
  description = "CloudFront distribution domain name (for DNS CNAME)"
}

output "distribution_arn" {
  value       = aws_cloudfront_distribution.frontend.arn
  description = "CloudFront distribution ARN"
}
