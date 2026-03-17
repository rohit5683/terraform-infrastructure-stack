variable "env" {
  type        = string
  description = "Environment name (e.g., prod, stage, dev)"
}

variable "domain_name" {
  type        = string
  description = "Custom domain name for CloudFront (e.g., app.prod.iac.rvdevops.com)"
}

variable "alb_dns_name" {
  type        = string
  description = "DNS name of the Application Load Balancer"
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate in us-east-1 for CloudFront"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources"
}
