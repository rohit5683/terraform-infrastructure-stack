variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_endpoints_sg_id" {
  type        = string
  description = "SG ID of VPC Endpoints (for SSM outbound)"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "restrict_to_cloudfront" {
  type        = bool
  description = "If true, Frontend ALB only accepts traffic from CloudFront. If false, open to world."
  default     = true
}

